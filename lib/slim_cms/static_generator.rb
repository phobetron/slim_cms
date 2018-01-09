require 'fileutils'
require 'rack/test'

module SlimCms
  class StaticGenerator
    include Rack::Test::Methods

    def app
      Rack::Builder.parse_file(File.expand_path('config.ru', Dir.pwd)).first
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

      ensure_dir_exists(output_path)

      archive(output_path)

      File.open(output_path, 'w') do |file|
        file.write(content)
      end
    end

    def archive(path)
      if (File.exist?(path))
        dirname = "archive/#{Time.now.strftime('%Y%m%d-%H%M')}"
        output_path = Pathname.new(File.join(Dir.pwd, dirname, path))

        ensure_dir_exists(output_path)

        File.cp(path, output_path)
      end
    end

    private

    def ensure_dir_exists(path)
      dirname = path.dirname

      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end
    end
  end
end
