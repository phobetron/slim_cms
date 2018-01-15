require 'fileutils'
require 'rack/test'

module SlimCms
  class StaticGenerator
    include Rack::Test::Methods

    def app
      @app ||= Rack::Builder.parse_file(File.expand_path('config.ru', Dir.pwd)).first
      @app.set :static, false
      @app
    end

    def generate_views(sitemap)
      sitemap.keys.each do |path|
        meta = sitemap[path]

        output_path = meta[:directory] ? "#{path}/index.html" : path.dup
        output_path.gsub!('//', '/')

        write(output_path, get(path).body)

        generate_views(meta[:children]) if meta[:children]
      end
    end

    def generate_robots_txt
      write('robots.txt', get('robots.txt').body)
    end

    def generate_sitemap_xml
      write('sitemap.xml', get('sitemap.xml').body)
    end

    def generate_stylesheets
      Pathname.new('assets/stylesheets').children.each do |child_path|
        output_path = child_path.sub('assets/', '').sub('.scss', '.css')

        write(output_path, get("/#{output_path}").body) unless Pathname.new(output_path).basename.to_s.start_with?('_')
      end
    end

    def write(path, content)
      output_path = Pathname.new(File.join(Dir.pwd, 'public', path))

      ensure_dir_exists(output_path)

      File.open(output_path, 'w') do |file|
        file.write(content)
      end
    end

    private

    def ensure_dir_exists(path)
      dirname = path.dirname

      unless dirname.directory?
        FileUtils.mkdir_p(dirname)
      end
    end
  end
end
