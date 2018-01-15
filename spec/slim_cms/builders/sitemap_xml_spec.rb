require 'spec_helper'

describe SlimCms::Builders::SitemapXml do
  let(:sitemap) do
    SlimCms::Sitemap.new(
      Pathname.new(File.dirname(__FILE__)) + '../../fixtures',
      Pathname.new(File.dirname(__FILE__)) + '../../fixtures/config_exist',
      Pathname.new(File.dirname(__FILE__)) + '../../fixtures/views'
    )
  end

  let(:domain) { 'http://example.com' }

  subject do
    described_class.new(sitemap, domain)
  end

  describe '#build' do
    it 'outputs the sitemap in XML format' do
      xml = subject.build

      expect(xml).to match('<\?xml version="1.0"\?>')
    end

    it 'outputs an entry for each page' do
      xml = subject.build

      expect(xml).to match('<loc>http://example.com/</loc>')
      expect(xml).to match('<loc>http://example.com/file</loc>')
      expect(xml).to match('<loc>http://example.com/sub</loc>')
      expect(xml).to match('<loc>http://example.com/sub/file</loc>')
    end

    it 'outputs the modified date for each page' do
      xml = subject.build

      expect(xml).to match('<lastmod>2016-05-12 05:12:05 -0700</lastmod>')
      expect(xml).to match('<lastmod>2016-05-12 04:59:49 -0700</lastmod>')
      expect(xml).to match('<lastmod>2016-05-12 05:14:17 -0700</lastmod>')
      expect(xml).to match('<lastmod>2016-05-12 04:59:49 -0700</lastmod>')
    end
  end
end
