ENV['RACK_ENV'] = 'test'

require 'bundler/setup'
Bundler.setup

require 'slim_cms'

Sinatra::Application.set :root, File.join(File.dirname(__FILE__), 'fixtures')

RSpec.configure do |config|
end
