require 'open-uri'
require 'nokogiri'

YAHOO_BASE_URL = 'http://local.yahooapis.com/MapsService/V1/geocode?appid=2AnYx1bV34G8gR9rYmMQPTs.uwTEcw9bMv8HXPhThIzLoS5_EjRXBcyQpNsYKg--&'

def geocode(location)
  url = URI.escape("http://geocoder.ca?geoit=XML&locate=#{location}")
  doc = Nokogiri::XML(open(url))
  return doc.at_css('latt').inner_text.to_f, doc.at_css('longt').inner_text.to_f
end

def yahoo_geocode(opts)
  url = URI.escape(YAHOO_BASE_URL + "street=#{opts[:street]}&city=#{opts[:city]}&state=ON")
  doc = Nokogiri::XML(open(url))
  return doc.at_css('Latitude').inner_text.to_f, doc.at_css('Longitude').inner_text.to_f
end
