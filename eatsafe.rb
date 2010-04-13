require 'sinatra'
require 'sequel'
require 'json'
require 'models'

get '/' do
  "Ottawa EatSafe API"
end

get '/facility/:id' do
  Facility[params[:id]].to_json
end
