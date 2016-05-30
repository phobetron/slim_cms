require 'spec_helper'

describe SlimCms::Sitemap do
  context '.new' do
    it 'accepts the root path, config directory and view directory arguments'

    context 'when config file exists' do
      it 'loads entries from the config file'
    end

    context 'when config file does not exist' do
      context 'when view directory exists' do
        it 'scans the view directory'
      end

      context 'when view directory does not exist' do
        it 'returns nil'
      end
    end
  end

  context '#all_entries' do
    context 'entries are not yet loaded' do
      it 'loads the YAML file and returns its entries'
    end

    context 'entries are already loaded' do
      it 'returns the loaded entries'
    end
  end

  context '#reload_entries' do
    context 'entries are not yet loaded' do
      it 'loads the YAML file and returns its entries'
    end

    context 'entries are already loaded' do
      it 'loads the YAML file and returns its entries anyway'
    end
  end

  context '#generate' do
    it 'scans views using the view file scanner'
    it 'writes the YAML config file'
    it 'reloads entries from YAML config file'
  end

  context '#top_level_entries' do
    context 'root level exists' do
      it 'returns the immediate children of the root level'
      it 'does not return any further descendents'
      it 'marks the top level for the current route as selected'
    end

    context 'root level does not exist' do
      it 'returns nil'
    end
  end

  context '#ancestry_for' do
    it 'finds all the ancestors for the given route, including the route entry'
  end

  context '#find' do
    context 'entry exists for route' do
      it 'returns the entry for the given route within the entry hierarchy'
    end

    context 'entry does not exist for route' do
      it 'returns nil'
    end
  end

  context '#update' do
    it 'updates the entry for the given route with the new properties'

    context 'can write the YAML file' do
      it 'writes changes to the YAML file'
    end

    context 'can not write the YAML file' do
      it 'returns nil'
    end
  end
end
