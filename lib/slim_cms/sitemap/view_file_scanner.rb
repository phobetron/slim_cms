require 'slim'
require 'slim_cms/sitemap/mock_render_scope'

module SlimCms
  class ViewFileScanner

    def initialize(root_path, view_path)
      @root_path = Pathname.new(root_path)
      @view_path = Pathname.new(view_path)
    end

    def scan(path, entries={})
      path = Pathname.new(path) if path.class == String
      entries ||= {}

      route = route_for(path)
      view_path = view_path_for(path)

      entry = entries[route.to_s] ||= {}
      entry[:view_path] = view_path.to_s
      entry[:last_modified] = path.mtime

      mock_scope = SlimCms::MockRenderScope.new(route, entry)

      if path.file?
        Slim::Template.new(path).render(mock_scope)
      elsif has_index_view?(entry)
        Slim::Template.new(path + 'index.slim').render(mock_scope)
      end

      entry.merge!(mock_scope.meta) if mock_scope.meta

      if path.directory?
        entry[:directory] = true
        entry[:indexed] = has_index_view?(entry)

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
      view_path.sub("#{@root_path.to_s}/", '')
    end

    def route_for(path)
      route = path.cleanpath.sub(@view_path.to_s, '')
      route = route.sub_ext('.html') if route.extname == '.slim'
      route = route.sub(/index(?:\.html)$/, '')

      route.to_s.size == 0 ? '/' : route
    end

    def has_index_view?(entry)
      entry[:view_path].end_with?('index.slim')
    end

  end
end
