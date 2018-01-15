require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/partial'
require 'sinatra/helpers'
require 'slim_cms'

module Sinatra
  module SlimCms
    def self.registered(app)
      app.helpers RenderHelpers, SiteHelpers, TextHelpers

      app.set :partial_template_engine, :slim

      app.set :config, File.join(app.root || File.dirname(__FILE__), 'config')
      app.set :archive, File.join(app.root || File.dirname(__FILE__), 'archive')
      app.set :host, 'example.org'
      app.set :scheme, 'http'

      app.before do
        @sitemap ||= ::SlimCms::Sitemap.new(app.root, app.config, app.views)
        @sitemap.generate
      end

      app.get '/robots.txt' do
        content_type 'text/plain', charset: 'utf-8'
        ::SlimCms::Builders::RobotsTxt.new(@sitemap).build
      end

      app.get '/sitemap.xml' do
        content_type 'text/xml', charset: 'utf-8'
        ::SlimCms::Builders::SitemapXml.new(@sitemap, settings.scheme + '://' + settings.host).build
      end

      app.get '/stylesheets/*.css' do
        content_type 'text/css', charset: 'utf-8'
        render_style params[:splat].first
      end

      app.get '/*' do
        @route = "/#{ params[:splat].compact.reject { |s| s.empty? }.first }"

        if @route.size > 1 && @route.end_with?('/')
          redirect @route.chop, 301
        end

        raise Sinatra::NotFound unless @page = @sitemap.find(@route)

        @index = @page[:children].clone rescue nil

        if !!@page[:directory] && !@page[:indexed]
            render_view 'common/index'
        else
          render_view @page[:view_path]
        end
      end
    end
  end

  register SlimCms
end
