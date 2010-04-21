require 'scraper'

namespace :scrape do
  desc "Full scrape"
  task :full do
    scrape
  end

  desc "Incremental scrape"
  task :incr do
    scrape(false)
  end

  desc "Geocode facility addresses"
  task :geocode do
    geocode
  end
end
