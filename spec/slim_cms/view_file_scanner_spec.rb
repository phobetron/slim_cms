require 'spec_helper'

describe SlimCms::ViewFileScanner do
  let(:root_path) { Pathname.new(File.dirname(__FILE__)) + '../fixtures' }
  let(:view_path) { Pathname.new(File.dirname(__FILE__)) + '../fixtures/views' }

  subject { described_class.new(root_path, view_path) }

  describe '#scan' do
    let(:meta) { { key: 'value' } }
    let(:mock_scope) { double(meta: meta) }
    let(:mock_slim) { double }
    let(:scan) { subject.scan(view_path) }

    before do
      allow(SlimCms::MockRenderScope).to receive(:new).with(any_args).and_return(mock_scope)
      allow(Slim::Template).to receive(:new).with(any_args).and_return(mock_slim)
      allow(mock_slim).to receive(:render).with(any_args)
    end

    it 'adds an entry by route for each file in the given path' do
      expect(scan.keys.first).to eq('/')
      expect(scan['/'][:children].keys.first).to eq('/file.html')
    end

    it 'adds view path to the entry' do
      expect(scan['/'][:view_path]).to eq('views/index.slim')
      expect(scan['/'][:children]['/file.html'][:view_path]).to eq('views/file.slim')
    end

    it 'adds modified time to the entry' do
      expect(scan['/'][:last_modified]).to be_a(Time)
      expect(scan['/'][:children]['/file.html'][:last_modified]).to be_a(Time)
    end

    context 'if view path is to a file' do
      it 'runs the view file in slim' do
        expect(Slim::Template).to receive(:new).with(any_args)
        scan
      end

      it 'merges meta data from the slim scope into the entry' do
        expect(scan['/'][:children]['/file.html'][:key]).to eq('value')
      end
    end

    context 'if path is to a directory' do
      it 'marks the entry as a directory' do
        expect(scan['/'][:directory]).to be true
        expect(scan['/'][:children]['/file.html'][:directory]).to be_nil
        expect(scan['/'][:children]['/sub'][:directory]).to be true
      end

      it 'scans any path children' do
        expect(scan['/'][:children]['/sub'][:children]).not_to be_nil
      end

      it 'excludes files and directories named common, layout, or index' do
        expect(scan.keys).to eq(['/'])
        expect(scan['/'][:children].keys).to eq(['/file.html', '/sub'])
      end

      context 'if view path exists and is an index' do
        it 'marks the entry as indexed' do
          expect(scan['/'][:indexed]).to be true
          expect(scan['/'][:children]['/sub'][:indexed]).to be false
        end

        it 'runs the view file in slim' do
          expect(Slim::Template).to receive(:new).with(any_args)
          scan
        end

        it 'merges meta data from the slim scope into the entry' do
          expect(scan['/'][:key]).to eq('value')
        end
      end
    end
  end

  describe '#clean' do
    let(:scan) do
      map = subject.scan(view_path)
      map['/'][:children]['/nonexistent'] = { view_path: 'views/nonexistent.slim' }
      map['/'][:children]['/sub'][:children]['/sub/nonexistent'] = { view_path: 'views/sub/nonexistent.slim' }

      map
    end

    let(:clean) { subject.clean(scan) }

    it 'deletes entries whose view paths no longer exist' do
      expect(clean['/'][:children].keys).not_to include('/nonexistent')
    end

    context 'entry is a directory' do
      it 'cleans entry directory children' do
        expect(clean['/'][:children]['/sub'].keys).not_to include('/sub/nonexistent')
      end
    end
  end
end
