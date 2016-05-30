ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.setup

require 'slim_cms'

RSpec.configure do |config|
end
