require 'logger'
require 'nokogiri'
require 'open-uri'
require 'geocoder'
require 'dm-core'
DataMapper::Logger.new($stdout, :debug)
require 'models'

INDEX_BASE_URL = 'http://ottawa.ca/cgi-bin/search/inspections/q.pl?ss=results_en&qt=fsi_s&sq_app_id=fsi'
FACILITY_BASE_URL = "http://ottawa.ca/cgi-bin/search/inspections/q.pl?ss=details_en&sq_fs_fdid="
@log = Logger.new(STDOUT)

@compliance_results = {}
@compliance_categories = {}
@compliance_descriptions = {}
@risk_levels = {}
@categories = {}


def scrape(full=true)
  if full
    [Facility, Inspection, Question, Comment, ComplianceResult, ComplianceCategory, ComplianceDescription, RiskLevel, FacilityCategory].each { |m| m.auto_migrate! }
    base_url = INDEX_BASE_URL
    @log.info "EatSafe full scrape started."
  else
    base_url = INDEX_BASE_URL + ';sort=fs_fcr_date%20desc'
    @log.info "EatSafe incremental scrape started."
  end

  first_page = Nokogiri::XML(open(base_url))
  total_facilities = first_page.xpath('//result')[0]['numFound'].to_i
  total_pages = total_facilities / 10 + (total_facilities % 10 == 0 ? 0 : 1)

  @log.info "Scraping index page 1"
  scrape_index_page(first_page)

  2.upto(total_pages).each do |page|
    @log.info "Scraping index page #{page}"
    url = base_url + ";start=#{page*10}"
    break if scrape_index_page(Nokogiri::XML(open(url)), full)
  end

  @compliance_results.each { |id, text| ComplianceResult.first_or_create(:id => id).update(:text_en => text) }
  @compliance_categories.each { |id, text| ComplianceCategory.first_or_create(:id => id).update(:text_en => text) }
  @risk_levels.each { |id, text| RiskLevel.first_or_create(:id => id).update(:text_en => text) }
  @compliance_descriptions.each do |id, values|
    risk_level_id = values.delete(:risk_level_id)
    compliance_description = ComplianceDescription.first_or_create(:id => id)
    compliance_description.attributes = values
    compliance_description.risk_level = RiskLevel.get(risk_level_id)
    compliance_description.save
  end
  @categories.each { |id, text| FacilityCategory.first_or_create(:id => id).update(:text_en => text) }

  @log.info "EatSafe scrape complete."
end

def scrape_index_page(index, full=true)
  incremental_done = false

  index.xpath('//doc').each do |facility_xml|
    facility_id = facility_xml.str('fdid')

    # check if we have reached the end of the new inspections
    if !full and facility = Facility.get(facility_id)
      last_update = facility.updated_at.to_date
      if last_update and Time.parse(facility_xml.str('fcr_date')).to_date < last_update
        incremental_done = true
        break
      end
    end
    scrape_facility_page(facility_id)
  end
  incremental_done # have we reached the end of the new inspections?
end

def scrape_facility_page(facility_id)
  facility_xml = Nokogiri::XML(open(FACILITY_BASE_URL + facility_id)).at_xpath('//doc')
  facility = {:id => facility_id}
  Facility.get(facility_id).destroy rescue true

  facility[:name] = facility_xml.str('fnm')
  facility[:street_number] = facility_xml.str('fsf')
  facility[:street_name] = facility_xml.str('fss')
  facility[:postal_code] = facility_xml.str('fspc')
  facility[:area_en] = facility_xml.str('fa_en')
  facility[:city] = facility_xml.str('fsc')
  facility[:phone] = cleanup_phone(facility_xml.str('fsph'))
  facility[:facility_category_id] = facility_xml.str('ftcd')

  @categories[facility[:facility_category_id]] = facility_xml.str('ft_en')

  facility_xml.arr('insp_en').xpath('./inspection').each do |inspection_xml|
    inspection = {:facility_id => facility_id}

    inspection[:id] = inspection_xml['inspectionid']
    inspection[:report_number] = inspection_xml['reportnumber'].to_i
    inspection[:inspection_date] = Date.parse(inspection_xml['inspectiondate'])
    inspection[:closure_date] = Time.parse(inspection_xml['closuredate'])
    inspection[:in_compliance] = inspection_xml['insincompliance'] == '1' ? true : false

    Inspection.get(inspection[:id]).destroy rescue true

    inspection_xml.xpath('./question').each do |question_xml|
      question = {:inspection_id => inspection[:id]}
      comments = []

      question[:sort] = question_xml['sort'].to_i
      question[:compliance_result_id] = question_xml['complianceresultcode']
      question[:compliance_category_id] = question_xml['compliancecategorycode']
      question[:compliance_description_id] = question_xml['compliancedecriptioncode'] # typo in EatSafe xml attr

      @compliance_results[question[:compliance_result_id]] = question_xml['complianceresulttext']
      @compliance_categories[question[:compliance_category_id]] = question_xml['compliancecategorytext']
      @compliance_descriptions[question[:compliance_description_id]] = {
        :text_en => question_xml.at_xpath('./qtext').inner_text,
        :risk_level_id => question_xml['risklevelid'] }
      @risk_levels[question_xml['risklevelid']] = question_xml['riskleveltext']

      question_xml.xpath('./comment').each { |comment| comments << comment.inner_text }

      q = Question.create(question)
      comments.each { |comment| q.comments.create(:text_en => comment).save }
      q.save
    end

    Inspection.create(inspection)
  end

  Facility.create(facility)
end

def cleanup_phone(phone)
  phone.gsub!(/\D/, '') # remove all non-digit characters
  phone = '613' + phone if phone.length == 7 # add 613 if not already there
  phone.sub!(/(\d{3})(\d{3})(\d{4})/, '\1-\2-\3') # format the number like 613-555-1212
  return phone.length == 12 ? phone : nil # return phone number unless the length is wrong
end

def geocode
  @log.info "Eatsafe Geocoder started"
  Facility.all(:lat => nil).each do |facility|
    if coords = FacilityCoordinate.get(facility.id)
      facility.update(:lat => coords.lat, :lon => coords.lon)
    else
      begin
        lat, lon = yahoo_geocode(:street => "#{facility.street_number} #{facility.street_name}", :city => facility.city)
      rescue
        sleep(5)
        next
      end
      facility.update(:lat => lat, :lon => lon)
      FacilityCoordinate.create(:id => facility.id, :lat => lat, :lon => lon)
    end
  end
end

class Nokogiri::XML::Node
  def str(attribute)
    at_xpath("./str[@name='fs_#{attribute}']").inner_text.strip
  end

  def arr(attribute)
    at_xpath("./arr[@name='fs_#{attribute}']")
  end
end
