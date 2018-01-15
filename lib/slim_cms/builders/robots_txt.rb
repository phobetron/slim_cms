module SlimCms::Builders
  class RobotsTxt
    def initialize(sitemap)
      @sitemap = sitemap
    end

    attr_reader :sitemap

    def build
      output = ['Sitemap: /sitemap.xml']

      groups_from_sitemap.each_pair do |ua, directives|
        group = ["user-agent: #{ua}"]
        group.concat(directives.sort)

        output << group.join("\n")
      end

      output.join("\n\n")
    end

    private

    def groups_from_sitemap
      groups = { '*' => [] }

      sitemap.flatten.each_pair do |path, meta|
        if meta[:robots]
          meta[:robots].each_pair do |ua, directive|
            groups[ua.downcase] ||= []

            groups[ua.downcase] << "#{directive.downcase}: #{path}"
          end
        end
      end

      groups
    end
  end
end
