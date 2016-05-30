require 'spec_helper'

describe 'SlimCms::VERSION' do
  it 'is a version number string' do
    expect(defined? SlimCms::VERSION).to eq('constant')
    expect(SlimCms::VERSION.class).to eq(String)
  end
end
