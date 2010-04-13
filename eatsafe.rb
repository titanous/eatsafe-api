require 'sinatra'
require 'dm-core'
require 'dm-serializer'
require 'models'

get '/' do
  "Ottawa EatSafe API"
end

get '/facility/:id' do
  Facility.get(params[:id]).to_json(:relationships => { 
    :inspections => {
      :exclude => :facility_id,
      :relationships => {
        :questions => { 
          :exclude => [:inspection_id, :compliance_category_id, :compliance_description_id, :compliance_result_id],
          :methods => [:category, :description, :result]
        }
      }
    }
  })
end
