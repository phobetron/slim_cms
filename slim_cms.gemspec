# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slim_cms/version'

Gem::Specification.new do |gem|
  gem.authors       = ['Charles Hudson']
  gem.email         = ['phobetron@gmail.com']
  gem.description   = 'Slim CMS'
  gem.summary       = 'Slim CMS that lets you create a website with Slim & Sass like it was static'
  gem.homepage      = 'https://github.com/phobetron/slim_cms'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.bindir        = 'exe'
  gem.executables   = gem.files.grep(%r{^exe/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'slim_cms'
  gem.require_paths = ['lib']
  gem.version       = SlimCms::VERSION

  gem.add_dependency 'nokogiri'
  gem.add_dependency 'rack-test'
  gem.add_dependency 'sinatra'
  gem.add_dependency 'sinatra-contrib'
  gem.add_dependency 'sinatra-export'
  gem.add_dependency 'sinatra-partial'
  gem.add_dependency 'sass'
  gem.add_dependency 'slim'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'byebug'
  gem.add_development_dependency 'sinatra-reloader'
  gem.add_development_dependency 'rspec'
end
