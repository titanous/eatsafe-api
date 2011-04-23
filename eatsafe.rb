require './models'
require './geocoder'

get '/' do
  '<h1>Ottawa EatSafe API</h1><br>See <a href="http://github.com/titanous/eatsafe-api">http://github.com/titanous/eatsafe-api</a>'
end

get '/facility/:id' do
  Facility.get(params[:id]).to_json(
    :relationships => { 
      :inspections => {
        :exclude => [:facility_id],
        :relationships => {
          :questions => { 
            :exclude => [:id, :inspection_id, :compliance_category_id, :compliance_description_id, :compliance_result_id, :created_at, :updated_at],
            :methods => [:category, :description, :result, :risk_level],
            :relationships => { :comments => { :exclude => [:question_id] } }
          }
        }
      }
    },
    :methods => [:category]
  )
end

get '/facilities/nearby' do
  halt 400, 'lat/lon or address not provided' unless (params[:lat] and params[:lon]) or params[:address]
  lat, lon = params[:address] ? geocode(params[:address]) : [params[:lat], params[:lon]]
  Facility.nearby(:lat => lat, :lon => lon, :filter => params[:q], :limit => params[:limit]).to_json
end

get '/facilities/search' do
 halt 400, 'search term no provided' unless params[:q]
 Facility.search(params[:q]).to_json
end
