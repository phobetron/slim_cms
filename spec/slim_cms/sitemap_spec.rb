require 'spec_helper'

describe SlimCms::Sitemap do
  let(:scanner) { double }
  let(:scan) do
    {
      '/' => {
        view_path: 'views/index.slim',
        directory: true,
        indexed: true,
        robots: { '*' => :allow },
        children: {
          '/file' => {
            view_path: 'views/file.slim',
            robots: { '*' => :allow },
          },
          '/sub' => {
            view_path: 'views/sub',
            directory: true,
            robots: { '*' => :disallow },
            children: {
              '/sub/file' => { view_path: 'views/sub/file.slim' }
            }
          }
        }
      }
    }
  end

  before do
    allow(SlimCms::ViewFileScanner).to receive(:new).with(any_args).and_return(scanner)
    allow(scanner).to receive(:scan).and_return(scan)
    allow(scanner).to receive(:clean).and_return(scan)
    allow_any_instance_of(described_class).to receive(:write)
  end

  subject do
    described_class.new(
      Pathname.new(File.dirname(__FILE__)) + '../fixtures',
      'config',
      'views'
    )
  end

  describe '.new' do
    context 'when config file does not exist' do
      context 'when view directory exists' do
        it 'scans the view directory' do
          expect_any_instance_of(described_class).not_to receive(:all_entries)
          expect_any_instance_of(described_class).to receive(:generate)
          subject
        end
      end

      context 'when view directory does not exist' do
        subject do
          described_class.new(
            Pathname.new(File.dirname(__FILE__)) + '../fixtures',
            'config',
            'views_nonexistent'
          )
        end

        it 'does nothing' do
          expect_any_instance_of(described_class).not_to receive(:all_entries)
          expect_any_instance_of(described_class).not_to receive(:generate)
          subject
        end
      end
    end

    context 'when config file exists' do
      subject do
        described_class.new(
          Pathname.new(File.dirname(__FILE__)) + '../fixtures',
          'config_exist',
          'views'
        )
      end

      it 'loads entries from the config file' do
        expect_any_instance_of(described_class).to receive(:all_entries)
        expect_any_instance_of(described_class).not_to receive(:generate)
        subject
      end
    end
  end

  describe '#all_entries' do
    subject do
      described_class.new(
        Pathname.new(File.dirname(__FILE__)) + '../fixtures',
        'config_exist',
        'views_nonexistent'
      )
    end

    context 'entries are not yet loaded' do
      it 'loads the YAML file and returns its entries' do
        entries = subject.all_entries

        expect(entries['/'][:children]['/file']).not_to be_nil
      end
    end

    context 'entries are already loaded' do
      it 'returns the loaded entries' do
        entries = subject.all_entries
        entries['/'][:children]['/whatever'] = {}
        entries = subject.all_entries

        expect(entries['/'][:children]['/whatever']).not_to be_nil
      end
    end
  end

  describe '#reload_entries' do
    subject do
      described_class.new(
        Pathname.new(File.dirname(__FILE__)) + '../fixtures',
        'config_exist',
        'views_nonexistent'
      )
    end

    context 'entries are not yet loaded' do
      it 'loads the YAML file and returns its entries' do
        entries = subject.reload_entries

        expect(entries['/'][:children]['/file']).not_to be_nil
      end
    end

    context 'entries are already loaded' do
      it 'loads the YAML file and returns its entries anyway' do
        entries = subject.all_entries
        entries['/'][:children]['/whatever'] = {}
        entries = subject.reload_entries

        expect(entries['/'][:children]['/whatever']).to be_nil
      end
    end
  end

  describe '#generate' do
    it 'scans views using the view file scanner' do
      expect(scanner).to receive(:scan)
      expect(scanner).to receive(:clean)
      subject.generate
    end

    it 'writes the YAML config file' do
      expect_any_instance_of(described_class).to receive(:write)
      subject.generate
    end

    it 'reloads entries from YAML config file' do
      expect_any_instance_of(described_class).to receive(:reload_entries).twice
      subject.generate
    end
  end

  describe '#top_level_entries' do
    context 'root level exists' do
      before do
        allow_any_instance_of(described_class).to receive(:all_entries).and_return(scan)
      end

      it 'returns the immediate children of the root level' do
        expect(subject.top_level_entries.keys).to eq(['/file', '/sub'])
      end

      it 'does not return any further descendents' do
        expect(subject.top_level_entries['/sub'][:children]).to be_nil
      end

      it 'marks the top level for the current route as selected' do
        expect(subject.top_level_entries('/file')['/file'][:selected]).to eq(true)
      end
    end

    context 'root level does not exist' do
      before do
        allow_any_instance_of(described_class).to receive(:all_entries).and_return({})
      end

      it 'returns nil' do
        expect(subject.top_level_entries).to be_nil
      end
    end
  end

  describe '#ancestry_for' do
    it 'finds all the ancestors for the given route, including the route entry' do
      expect(subject.ancestry_for('/sub/file', scan)).to eq([
        { '/' => { view_path: 'views/index.slim', directory: true, indexed: true, robots: { "*" => :allow } } },
        { '/sub' => { view_path: 'views/sub', directory: true, robots: { "*" => :disallow } } },
        { '/sub/file' => { view_path: 'views/sub/file.slim' } }
      ])
    end
  end

  describe '#find' do
    context 'entry exists for route' do
      it 'returns the entry for the given route within the entry hierarchy' do
        expect(subject.find('/sub/file', scan)).to eq({ view_path: 'views/sub/file.slim' })
      end
    end

    context 'entry does not exist for route' do
      it 'returns nil' do
        expect(subject.find('/sub/no_file', scan)).to be_nil
      end
    end
  end

  describe '#update' do
    before do
      allow_any_instance_of(described_class).to receive(:all_entries).and_return(scan)
    end

    it 'updates the entry for the given route with the new properties' do
      subject.update('/sub/file', { key: 'value' })
      expect(scan['/'][:children]['/sub'][:children]['/sub/file'][:key]).to eq('value')
    end

    context 'can write the YAML file' do
      before do
        allow_any_instance_of(described_class).to receive(:write).and_return(true)
      end

      it 'writes changes to the YAML file' do
        expect(subject.update('/sub/file', { key: 'value' })).to eq({
          view_path: 'views/sub/file.slim',
          key: 'value'
        })
      end
    end

    context 'can not write the YAML file' do
      before do
        allow_any_instance_of(described_class).to receive(:write).and_return(false)
      end

      it 'returns nil' do
        expect(subject.update('/sub/file', { key: 'value' })).to be_nil
      end
    end
  end

  describe '#flatten' do
    subject do
      described_class.new(
        Pathname.new(File.dirname(__FILE__)) + '../fixtures',
        'config_exist',
        'views'
      )
    end

    it 'lists all pages in the returned Hash' do
      flattened = subject.flatten

      expect(flattened['/']).not_to be_nil
      expect(flattened['/file']).not_to be_nil
      expect(flattened['/sub']).not_to be_nil
      expect(flattened['/sub/file']).not_to be_nil
    end

    it 'does not include children/hierarchy in metadata' do
      flattened = subject.flatten

      expect(flattened['/'][:children]).to be_nil
      expect(flattened['/sub'][:children]).to be_nil
    end
  end

  describe '#to_xml' do
    subject do
      described_class.new(
        Pathname.new(File.dirname(__FILE__)) + '../fixtures',
        'config_exist',
        'views'
      )
    end

    it 'outputs the sitemap in XML format' do
      xml = subject.to_xml('http://example.com/')

      expect(xml).to match('<\?xml version="1.0"\?>')
    end

    it 'outputs an entry for each page' do
      xml = subject.to_xml('http://example.com/')

      expect(xml).to match('<loc>http://example.com/</loc>')
      expect(xml).to match('<loc>http://example.com/file</loc>')
      expect(xml).to match('<loc>http://example.com/sub</loc>')
      expect(xml).to match('<loc>http://example.com/sub/file</loc>')
    end

    it 'outputs the modified date for each page' do
      xml = subject.to_xml('http://example.com/')

      expect(xml).to match('<lastmod>2016-05-12 05:12:05 -0700</lastmod>')
      expect(xml).to match('<lastmod>2016-05-12 04:59:49 -0700</lastmod>')
      expect(xml).to match('<lastmod>2016-05-12 05:14:17 -0700</lastmod>')
      expect(xml).to match('<lastmod>2016-05-12 04:59:49 -0700</lastmod>')
    end
  end

  describe '#robots' do
    subject do
      described_class.new(
        Pathname.new(File.dirname(__FILE__)) + '../fixtures',
        'config_exist',
        'views'
      )
    end

    it 'outputs a hash of path directives grouped by user agent' do
      robots = subject.robots

      expect(robots.keys).to eq(['*'])
    end
  end
end
