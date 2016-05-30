require 'spec_helper'

describe SlimCms::ViewFileScanner do
  context '.new' do
    it 'accepts the root path and view path arguments'
  end

  context '#scan' do
    it 'adds an entry by route for each file in the given path'
    it 'adds view path to the entry'
    it 'adds modified time to the entry'

    context 'if view path is to a file' do
      it 'runs the view file in slim'
      it 'merges meta data from the slim scope into the entry'
    end

    context 'if path is to a directory' do
      it 'marks the entry as a directory'
      it 'scans any path children'
      it 'excludes files and directories named common, layout, or index'

      context 'if view path exists and is an index' do
        it 'marks the entry as indexed'
      end
    end
  end

  context '#clean' do
    it 'deletes entries whose view paths no longer exist'

    context 'entry is a directory' do
      it 'cleans entry directory children'
    end
  end
end
