require 'fileutils'
require 'rack/test'

# TODO: archive old files

module SlimCms
  class StaticGenerator
    include Rack::Test::Methods

    def app
      Rack::Builder.parse_file(File.expand_path('config.ru', Dir.pwd)).first
    end

    def generate_views(sitemap)
      sitemap.keys.each do |path|
        meta = sitemap[path]

        output_path = meta[:directory] ? path + '/index.html' : path.dup
        output_path.gsub!('//', '/')

        write(output_path, get(path).body)

        generate_views(meta[:children]) if meta[:children]
      end
    end

    def generate_sitemap_xml
      write('sitemap.xml', get('sitemap.xml').body)
    end

    def generate_stylesheets
      Pathname.new('assets/stylesheets').children.each do |child_path|
        output_path = child_path.sub('assets/', '').sub('.scss', '.css')

        write(output_path, get(output_path).body) unless Pathname.new(output_path).basename.to_s.start_with?('_')
      end
    end

    def write(path, content)
      output_path = Pathname.new(File.join(Dir.pwd, 'public', path))
      output_dirname = output_path.dirname

      unless File.directory?(output_dirname)
        FileUtils.mkdir_p(output_dirname)
      end

      File.open(output_path, 'w') do |file|
        file.write(content)
      end
    end
  end
end
