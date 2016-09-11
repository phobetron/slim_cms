module SlimCms
  class MockRenderScope
    def initialize(route, entry={})
      @route = route
      @index = entry[:children]
    end

    def partial(*args)
      args.to_s
    end

    attr_accessor :meta
  end
end
