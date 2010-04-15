require 'open-uri'
require 'rexml/document'

def geocode(location)
  url = "http://geocoder.ca?geoit=XML&locate=#{location.gsub(/ /, '%20')}"
  doc = REXML::Document.new(open(url))
  return doc.elements['geodata/latt'].text, doc.elements['geodata/longt'].text
end
