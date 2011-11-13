require 'open-uri'
require 'nokogiri'
require './monkeys'

YAHOO_BASE_URL = 'http://where.yahooapis.com/geocode?appid=2AnYx1bV34G8gR9rYmMQPTs.uwTEcw9bMv8HXPhThIzLoS5_EjRXBcyQpNsYKg--&'

def geocode(location)
  url = URI.escape("http://geocoder.ca?geoit=XML&locate=#{location}")
  doc = Nokogiri::XML(open(url))
  return doc.at_css('latt').inner_text.to_f.round_to(4), doc.at_css('longt').inner_text.to_f.round_to(4)
end

def yahoo_geocode(location)
  url = URI.escape(YAHOO_BASE_URL + "q=#{location}")
  doc = Nokogiri::XML(open(url).read)
  return doc.at_css('latitude').inner_text.to_f.round_to(4), doc.at_css('longitude').inner_text.to_f.round_to(4)
end
