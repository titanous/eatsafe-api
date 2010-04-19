require 'logger'
require 'nokogiri'
require 'open-uri'
require 'models'

INDEX_BASE_URL = 'http://ottawa.ca/cgi-bin/search/inspections/q.pl?ss=results_en&qt=fsi_s&sq_app_id=fsi'
FACILITY_BASE_URL = "http://ottawa.ca/cgi-bin/search/inspections/q.pl?ss=details_en&sq_fs_fdid="
@log = Logger.new(STDOUT)

@compliance_results = {}
@compliance_categories = {}
@compliance_descriptions = {}
@risk_levels = {}
@categories = {}

@first_page = Nokogiri::XML(open(INDEX_BASE_URL))
total_facilities = @first_page.xpath('//result')[0]['numFound'].to_i
@total_pages = total_facilities / 10 + (total_facilities % 10 == 0 ? 0 : 1)

@log.info "EatSafe Scraper started. #{total_facilities} facilities to process."

def scrape
  DataMapper.auto_migrate!

  @log.info "Scraping index page 1"
  scrape_index_page(@first_page)

  2.upto(2).each do |page|
    @log.info "Scraping index page #{page}"
    url = INDEX_BASE_URL + ";start=#{page*10}"
    scrape_index_page(Nokogiri::XML(open(url)))
  end

  @compliance_results.each { |id, text| ComplianceResult.create(:id => id, :text_en => text).save }
  @compliance_categories.each { |id, text| ComplianceCategory.create(:id => id, :text_en => text).save }
  @compliance_descriptions.each { |id, values| ComplianceDescription.create(values.merge(:id => id)).save }
  @risk_levels.each { |id, text| RiskLevel.create(:id => id, :text_en => text).save }
end

def scrape_index_page(index)
  index.xpath('//doc').each do |facility_xml|
    facility_id = facility_xml.str('fdid')
    scrape_facility_page(facility_id)
  end
end

def scrape_facility_page(facility_id)
  facility_xml = Nokogiri::XML(open(FACILITY_BASE_URL + facility_id)).at_xpath('//doc')
  facility = {:id => facility_id}

  facility[:name] = facility_xml.str('fnm')
  facility[:street_number] = facility_xml.str('fsf')
  facility[:street_name] = facility_xml.str('fss')
  facility[:postal_code] = facility_xml.str('fspc')
  facility[:area_en] = facility_xml.str('fa_en')
  facility[:city] = facility_xml.str('fsc')
  facility[:phone] = cleanup_phone(facility_xml.str('fsph'))
  facility[:facility_category_id] = facility_xml.str('ftcd')

  @categories[facility[:category_id]] = facility_xml.str('ft_en')

  facility_xml.arr('insp_en').xpath('./inspection').each do |inspection_xml|
    inspection = {:facility_id => facility_id}

    inspection[:id] = inspection_xml['inspectionid']
    inspection[:report_number] = inspection_xml['reportnumber'].to_i
    inspection[:inspection_date] = Date.parse(inspection_xml['inspectiondate'])
    inspection[:closure_date] = Time.parse(inspection_xml['closuredate'])
    inspection[:in_compliance] = inspection_xml['insincompliance'] == '1' ? true : false

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

    Inspection.create(inspection).save
  end

  Facility.create(facility).save
end

def cleanup_phone(phone)
  phone.gsub!(/\D/, '') # remove all non-digit characters
  phone = '613' + phone if phone.length == 7 # add 613 if not already there
  phone.sub!(/(\d{3})(\d{3})(\d{4})/, '\1-\2-\3') # format the number like 613-555-1212
  return phone.length == 12 ? phone : nil # return phone number unless the length is wrong
end

class Nokogiri::XML::Node
  def str(attribute)
    at_xpath("./str[@name='fs_#{attribute}']").inner_text.strip
  end

  def arr(attribute)
    at_xpath("./arr[@name='fs_#{attribute}']")
  end
end

scrape
