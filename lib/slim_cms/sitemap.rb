require 'pathname'
require 'yaml'
require 'slim'

module SlimCms
  class Sitemap

    class MockScope
      def initialize(route, entry)
        @route = route
        @index = entry[:children]
      end

      def partial(*args)
        args.to_s
      end

      attr_accessor :meta
    end

    def initialize(root_path, conf_dir, view_dir)
      @root_path = Pathname.new(root_path)
      @view_path = @root_path + view_dir
      @conf_file = @root_path + (conf_dir + '/sitemap.yml')
      @conf_file.exist? ? all_entries : generate
    end

    def generate
      @sitemap = scan(@view_path, clean(all_entries))
      write
      reload_entries || nil
    end

    def all_entries
      @sitemap ||= YAML.load_file(@conf_file) rescue nil
    end

    def top_level_entries(current_route='/')
      all_entries['/'][:children].each_with_object({}) do |(er, entry), cats|
        cats[er] = entry.clone

        cats[er].delete(:children)
        cats[er][:selected] = true if er == current_route
      end
    end

    def find(route, entries=all_entries)
      entries.fetch(route) do |er|
        parent_route = entries.select { |pr| er.start_with?(pr) }.keys.last
        parent_route.nil? ? nil : find(er, entries[parent_route][:children] || {})
      end
    end

    def update(route, entry_updates)
      if entry = find(route)
        entry.merge!(entry_updates).reject! { |k, v| v.nil? }

        success = write
      end

      success ? entry : nil
    end

    def ancestry_for(route, entries=all_entries)
      entries
        .select { |er| route.start_with?(er) }
        .each_with_object([]) do |(er, entry), trail|
        trail << { "#{er}" => entry.clone }

        if children = trail.last.values.first.delete(:children)
          trail.concat(ancestry_for(route, children))
        end
      end
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

    def clean(entries={})
      return nil if entries.nil?

      entries.reject! { |route, entry| !(@root_path + entry[:view_path]).exist? }
      entries.select { |route, entry| entry.has_key? :children }
        .each_value { |entry| clean(entry[:children]) }

      entries
    end

    def scan(path, entries={})
      path = Pathname.new(path) if path.class == String
      entries ||= {}

      route = route_for(path)
      view_path = view_path_for(path)

      entry = entries[route.to_s] ||= {}
      entry[:view_path] = view_path.to_s
      entry[:last_modified] = path.mtime

      if view_path.file?
        mock_scope = MockScope.new(route, entry)
        Slim::Template.new(entry[:view_path]).render(mock_scope)

        entry.merge!(mock_scope.meta) if mock_scope.meta
      end

      if path.directory?
        entry[:directory] = true
        entry[:indexed] = entry[:view_path].end_with?('index.slim')

        path.children.reject { |child_path| excluded?(child_path) }.each do |child_path|
          scan(child_path, entry[:children] ||= {})
        end
      end

      entries
    end

    def excluded?(path)
      @exclude_names ||= [ 'common', 'layout', 'index' ]
      !path || @exclude_names.include?(path.basename.sub_ext('').to_s)
    end

    def view_path_for(path)
      view_path = path.cleanpath
      if view_path.basename != 'index.slim' && (view_path + 'index.slim').exist?
        view_path = view_path + 'index.slim'
      end
      view_path.sub(@root_path.to_s + '/', '')
    end

    def route_for(path)
      route = path.cleanpath.sub(@view_path.to_s, '').sub_ext('').sub(/index$/, '')
      route.to_s.size == 0 ? '/' : route
    end

  end
end
