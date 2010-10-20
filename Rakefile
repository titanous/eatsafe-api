require 'bundler'
Bundler.require
require 'scraper'
require 'hoptoad_config'
require 'hoptoad_notifier/tasks'

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

task :environment do # stub for hoptoad:deploy
end

task :deploy do
  puts 'Deploying to Heroku...'
  system 'git push -f heroku master'

  puts 'Notifying Errbit of Deploy...'
  revision = `git rev-parse HEAD`.chomp
  repo = `git remote -v | grep -m1 origin | cut -f2 | cut -f1 -d' '`.chomp
  local_user = ENV['USER'] || ENV['USERNAME']

  cmd = "heroku rake hoptoad:deploy TO=production REVISION=#{revision}"
  system cmd << "REPO=#{repo} USER=#{local_user}"
end
