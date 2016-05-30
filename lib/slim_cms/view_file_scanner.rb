require 'slim'

module SlimCms
  class ViewFileScanner

    def initialize(root_path, view_path)
      @root_path = root_path
      @view_path = view_path
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
        mock_scope = SlimCms::MockRenderScope.new(route, entry)
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

    def clean(entries={})
      return nil if entries.nil?

      entries.reject! { |route, entry| !(@root_path + entry[:view_path]).exist? }
      entries.select { |route, entry| entry.has_key? :children }
        .each_value { |entry| clean(entry[:children]) }

      entries
    end

    private

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
