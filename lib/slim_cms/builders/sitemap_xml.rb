module SlimCms::Builders
  class SitemapXml
    def initialize(sitemap, domain)
      @sitemap = sitemap
      @domain = domain.chomp('/')
    end

    attr_reader :sitemap, :domain

    def build
      Nokogiri::XML::Builder.new do
        urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') {
          sitemap.flatten.each do |path, meta|
            url {
              loc     "#{domain}#{path}"
              lastmod meta[:last_modified]
            }
          end
        }
      end.to_xml
    end
  end
end
