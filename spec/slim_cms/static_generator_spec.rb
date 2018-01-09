require 'spec_helper'
require 'fileutils'

describe SlimCms::StaticGenerator do
  let(:app)          { double('App') }
  let(:pwd)          { '/path' }
  let(:app_path)     { '/path/config.ru' }
  let(:content)      { double('Content') }
  let(:content_body) { 'content' }

  let(:sitemap)  do
    {
      '/' => {
        directory: true,
        children: {
          '/child.html' => {}
        }
      },
      '/top.html' => {}
    }
  end

  subject { described_class.new }

  before do
    allow(Rack::Builder).to receive(:parse_file).and_return([app])
    allow(FileUtils).to receive(:mkdir_p)
    allow(Dir).to receive(:pwd).and_return(pwd)

    allow(app).to receive(:call)
    allow(content).to receive(:body).and_return(content_body)

    allow(subject).to receive(:get).and_return(content)
  end

  context 'core generation methods' do
    before do
      allow(subject).to receive(:write)
    end

    describe '#app' do
      it 'uses Rack to create an instance of the host app' do
        expect(Rack::Builder).to receive(:parse_file).with(app_path)

        subject.app
      end
    end

    describe '#generate_views' do
      it 'creates a file for each sitemap entry' do
        expect(subject).to receive(:write).with('/index.html', content_body)
        expect(subject).to receive(:write).with('/top.html', content_body)

        subject.generate_views(sitemap)
      end

      it 'recursively crawls over child entries' do
        expect(subject).to receive(:write).with('/child.html', content_body)

        subject.generate_views(sitemap)
      end
    end

    describe 'generate_robots_txt' do
      it 'creates a robots.txt file' do
        expect(subject).to receive(:get).with('robots.txt')
        expect(subject).to receive(:write).with('robots.txt', content_body)

        subject.generate_robots_txt
      end
    end

    describe 'generate_sitemap_xml' do
      it 'creates a sitemap.xml file' do
        expect(subject).to receive(:get).with('sitemap.xml')
        expect(subject).to receive(:write).with('sitemap.xml', content_body)

        subject.generate_sitemap_xml
      end
    end

    describe '#generate_stylesheets' do
      let(:pathname) { double('Pathname') }
      let(:basename) { 'basename.scss' }
      let(:children) do
        [
          'assets/stylesheets/application.scss',
          'assets/stylesheets/page.scss'
        ]
      end

      before do
        expect(Pathname).to receive(:new).and_return(pathname).at_least(3).times
        expect(pathname).to receive(:basename).and_return(basename).at_least(2).times
        expect(pathname).to receive(:children).and_return(children)
      end

      it 'creates a stylesheet for each in the assets/stylesheets directory' do
        expect(subject).to receive(:write).with('stylesheets/application.css', content_body)
        expect(subject).to receive(:write).with('stylesheets/page.css', content_body)

        subject.generate_stylesheets
      end
    end
  end

  describe '#write' do
    let(:path) { '/dir/file.out' }

    before do
      allow(File).to receive(:directory?).and_return(true)
      allow(File).to receive(:open)
      allow(subject).to receive(:archive)
    end

    it 'creates directories for the given path if one does not exist' do
      dir_pathname = Pathname.new('/path/public/dir')

      expect_any_instance_of(Pathname).to receive(:directory?).and_return(false)
      expect(FileUtils).to receive(:mkdir_p).with(dir_pathname)

      subject.write(path, 'content')
    end

    it 'writes content to a file in the public dir at a given path' do
      expect(File).to receive(:open).with(Pathname.new("#{pwd}/public#{path}"), 'w')

      subject.write(path, 'content')
    end
  end
end
