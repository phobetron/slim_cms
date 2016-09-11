require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/partial'
require 'sass'
require 'slim'
require 'slim_cms/sitemap'

module Sinatra
  module SlimCms

    module Helpers
      def titleize(text)
        text.to_s.gsub(/_+/, ' ').gsub(/\b('?[a-z])/) { $1.capitalize }
      end

      def sections
        @sections ||= settings.sitemap
          .top_level_entries(@route || '/')
          .select { |route, entry| !!entry[:directory] }
      end

      def site_pages
        @site_pages ||= settings.sitemap
          .top_level_entries(@route || '/')
          .select { |route, entry| !entry[:directory] }
      end

      def breadcrumbs
        @breadcrumbs ||= settings.sitemap.ancestry_for(@route || '/')
          .reject { |crumb| crumb.keys.first.end_with?('/') }
      end

      def render_view(route)
        slim route.to_sym
      end

      def render_style(route)
        scss route.to_sym, :views => "assets/stylesheets"
      end
    end

    def self.registered(app)
      app.helpers SlimCms::Helpers

      app.set :partial_template_engine, :slim
      app.set :root, app.root || File.dirname(__FILE__)
      app.set :views, 'views'
      app.set :config, 'config'
      app.set :sitemap, ::SlimCms::Sitemap.new(app.root, app.config, app.views)

      app.get '/stylesheets/*.css' do
        content_type 'text/css', :charset => 'utf-8'
        render_style params[:splat].first
      end

      app.get '/*' do
        @route = "/#{ params[:splat].compact.reject { |s| s.empty? }.first }"

        if @route.size > 1 && @route.end_with?('/')
          redirect @route.chop, 301
        end

        raise Sinatra::NotFound unless @page = settings.sitemap.find(@route)

        @index = @page[:children].clone rescue nil

        if @route == '/'
          render_view @route + 'index'

        elsif !!@page[:directory]
          if !!@page[:indexed]
            render_view @route + '/index'
          else
            render_view 'common/index'
          end
        else
          render_view @route
        end
      end
    end
  end

  register SlimCms
end
