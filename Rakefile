require 'bundler'
Bundler.require(:default)
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

task :cron do
  if Date.today.wday == 0 # Sunday
    Rake::Task['scrape:full'].execute
  else
    Rake::Task['scrape:incr'].execute
  end
  Rake::Task['scrape:geocode'].execute
end
