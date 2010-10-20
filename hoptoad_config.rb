HoptoadNotifier.configure do |config|
  config.api_key = ENV['HOPTOAD_API_KEY']
  config.host    = 'logger.titanous.com'
  config.port    = 80
end
