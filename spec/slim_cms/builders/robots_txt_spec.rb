require 'spec_helper'

describe SlimCms::Builders::RobotsTxt do
  let(:sitemap) do
    SlimCms::Sitemap.new(
      Pathname.new(File.dirname(__FILE__)) + '../../fixtures',
      Pathname.new(File.dirname(__FILE__)) + '../../fixtures/config_exist',
      Pathname.new(File.dirname(__FILE__)) + '../../fixtures/views'
    )
  end

  subject do
    described_class.new(sitemap)
  end

  describe '#build' do
    it 'outputs sitemap pth' do
      robots = subject.build

      expect(robots).to match('Sitemap: /sitemap.xml')
    end

    it 'outputs directives grouped by user agent' do
      robots = subject.build

      expect(robots).to match('user-agent: *')
    end
  end
end
