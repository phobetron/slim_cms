require 'spec_helper'

describe SlimCms::MockRenderScope do
  let(:test_route) { 'test_route' }
  let(:test_entry) { { children: ['child'] } }

  subject { described_class.new(test_route, test_entry) }

  context 'assigns' do
    it 'has a route member' do
      expect(subject.instance_variable_get(:@route)).to eq(test_route)
    end

    it 'has an index member' do
      expect(subject.instance_variable_get(:@index)).to eq(test_entry[:children])
    end
  end

  context 'partial' do
    it 'stubs the partial method' do
      expect(subject.partial(1, 2)).to eq('[1, 2]')
    end
  end

  context 'meta' do
    it 'has an attribute sccessor for meta' do
      subject.meta = 'meta'
      expect(subject.meta).to eq('meta')
    end
  end
end
