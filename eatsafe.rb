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
          :methods => [:category, :description, :result],
          :relationships => { :comments => { :exclude => [:question_id] } }
        }
      }
    }
  })
end

get '/facilities/nearby' do
  halt 400, 'lat and/or lon not provided' unless params[:lat] and params[:lon]
  Facility.nearby(:lat => params[:lat], :lon => params[:lon], :limit => params[:limit]).to_json
end
