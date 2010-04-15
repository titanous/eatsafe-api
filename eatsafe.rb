require 'sinatra'
require 'models'
require 'geocoder'

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
  halt 400, 'lat/lon or address not provided' unless (params[:lat] and params[:lon]) or params[:address]
  lat, lon = params[:address] ? geocode(params[:address]) : [params[:lat], params[:lon]]
  Facility.nearby(:lat => lat, :lon => lon, :limit => params[:limit]).to_json
end
