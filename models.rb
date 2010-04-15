require 'dm-core'
require 'dm-serializer'

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

  def self.nearby(options)
    query = 'SELECT *, ACOS(SIN(RADIANS(lat)) * SIN(RADIANS(?)) + COS(RADIANS(lat)) * COS(RADIANS(?)) * COS(RADIANS(?) - RADIANS(lon))) * 6371 AS distance FROM facilities ORDER BY distance ASC LIMIT ?'
    repository(:default).adapter.select(query, options[:lat], options[:lat], options[:lon], (options[:limit] || 25))
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

  property :id, Integer, :length => 11, :key => true
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
end

class Comment
  include DataMapper::Resource

  property :text_en, String, :length => 255

  belongs_to :question
end

class Struct
  def to_json
    hash = {}
    each_pair { |name, value| hash[name] = value }
    hash.to_json
  end
end
