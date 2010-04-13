DB = Sequel.connect(ENV['DATABASE_URL'] || 'postgres://localhost/eatsafe')

class Facility < Sequel::Model
  one_to_many :inspections
end

class Inspection < Sequel::Model
  many_to_one :facility
  one_to_many :questions
end

class Question < Sequel::Model
  many_to_one :inspection
  many_to_one :compliance_result
  many_to_one :compliance_category
  many_to_one :compliance_description
end

class ComplianceResult < Sequel::Model
  one_to_many :questions
end

class ComplianceCategory < Sequel::Model
  one_to_many :questions
end

class ComplianceDescription < Sequel::Model
  one_to_many :questions
end

class Sequel::Dataset
  def to_json
    naked.all.to_json
  end
end

class Sequel::Model
  def to_json
    this.to_json
  end
end
