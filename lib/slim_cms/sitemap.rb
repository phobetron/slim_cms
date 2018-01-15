require 'nokogiri'
require 'pathname'
require 'yaml'
require 'slim_cms/sitemap/view_file_scanner'

module SlimCms
  class Sitemap
    def initialize(root_path, conf_dir, view_path)
      @root_path = Pathname.new(root_path)
      @view_path = Pathname.new(view_path)
      @conf_file = Pathname.new(File.join(conf_dir, 'sitemap.yml'))

      @scanner = ViewFileScanner.new(@root_path, @view_path)

      if @conf_file.exist?
        all_entries
      elsif @view_path.exist?
        generate
      end
    end

    def all_entries
      @sitemap ||= YAML.load_file(@conf_file) rescue nil
    end

    def reload_entries
      @sitemap = YAML.load_file(@conf_file) rescue nil
    end

    def generate
      @sitemap = @scanner.scan(@view_path, @scanner.clean(all_entries))
      write
      reload_entries
    end

    def top_level_entries(current_route='/')
      all_entries['/'][:children].each_with_object({}) do |(route, entry), cats|
        cats[route] = entry.clone

        cats[route].delete(:children)
        cats[route][:selected] = true if route == current_route
      end unless !all_entries.include?('/')
    end

    def ancestry_for(current_route, entries=all_entries)
      entries
        .select { |route| current_route.start_with?(route) }
        .each_with_object([]) do |(route, entry), trail|
        trail << { "#{route}" => entry.clone }

        if children = trail.last.values.first.delete(:children)
          trail.concat(ancestry_for(current_route, children))
        end
      end
    end

    def find(current_route, entries=all_entries)
      entries.fetch(current_route) do |route|
        parent_route = entries.select { |pr| route.start_with?(pr) }.keys.last
        parent_route.nil? ? nil : find(route, entries[parent_route][:children] || {})
      end
    end

    def update(route, entry_updates)
      if entry = find(route)
        entry.merge!(entry_updates).reject! { |k, v| v.nil? }

        success = write
      end

      success ? entry : nil
    end

    def flatten(entries=all_entries.dup, map={})
      entries.each do |path, meta|
        map[path] = meta.dup
        map[path].delete(:children)

        flatten(meta[:children], map) if meta[:children]
      end

      map
    end

    private

    def write
      begin
        File.open(@conf_file, 'w') { |f| YAML.dump(all_entries, f) }
        true
      rescue
        false
      end
    end
  end
end
