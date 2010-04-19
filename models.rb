require 'dm-core'
require 'dm-serializer'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/eatsafe')

class Facility
  include DataMapper::Resource

  property :id, String, :length => 40, :key => true
  property :name, String, :length => 255
  property :street_number, String
  property :street_name, String, :length => 255
  property :postal_code, String, :length => 10
  property :phone, String, :length => 20
  property :area_en, String, :length => 25
  property :city, String, :length => 35
  property :lat, Float
  property :lon, Float

  has n, :inspections
  belongs_to :facility_category

  def category
    facility_category.text_en
  end

  def self.nearby(options)
    query = 'SELECT *, ACOS(SIN(RADIANS(lat)) * SIN(RADIANS(?)) + COS(RADIANS(lat)) * COS(RADIANS(?)) * COS(RADIANS(?) - RADIANS(lon))) * 6371 AS distance FROM facilities ORDER BY distance ASC LIMIT ?'
    repository(:default).adapter.select(query, options[:lat], options[:lat], options[:lon], (options[:limit] || 25))
  end

  def self.search(term)
    term = '%' + term + '%'
    all(:conditions => ['name ILIKE ?', term], :limit => 100)
  end
end

class Inspection
  include DataMapper::Resource

  property :id, String, :length => 40, :key => true
  property :inspection_date, Date
  property :in_compliance, Boolean
  property :closure_date, DateTime
  property :report_number, Integer, :length => 11

  belongs_to :facility
  has n, :questions
end

class Question
  include DataMapper::Resource

  property :id, Serial
  property :sort, Integer, :length => 11

  belongs_to :inspection
  belongs_to :compliance_result
  belongs_to :compliance_category
  belongs_to :compliance_description
  has n, :comments

  def category
    compliance_category.text_en
  end

  def description
    compliance_description.text_en
  end

  def result
    compliance_result.text_en
  end
end

class ComplianceResult
  include DataMapper::Resource

  property :id, String, :length => 3, :key => true
  property :text_en, String, :length => 255

  has n, :questions
end

class ComplianceCategory
  include DataMapper::Resource

  property :id, String, :length => 4, :key => true
  property :text_en, String, :length => 255

  has n, :questions
end

class ComplianceDescription
  include DataMapper::Resource

  property :id, String, :length => 10, :key => true
  property :text_en, String, :length => 255

  has n, :questions
  belongs_to :risk_level
end

class Comment
  include DataMapper::Resource

  property :id, Serial
  property :text_en, String, :length => 255

  belongs_to :question
end

class RiskLevel
  include DataMapper::Resource

  property :id, String, :length => 2, :key => true
  property :text_en, String, :length => 255

  has n, :compliance_descriptions
end

class FacilityCategory
  include DataMapper::Resource

  property :id, String, :length => 5, :key => true
  property :text_en, String, :length => 255

  has n, :facilities
end

class Struct
  def to_json
    hash = {}
    each_pair { |name, value| hash[name] = value }
    hash.to_json
  end
end
