require 'spec_helper'

RSpec.describe Hanami::Action::Mime::Specification do
  let(:plain_text) { described_class.new('text/plain', 0.7, 2) }
  let(:any_text) { described_class.new('text/*', 1, 0) }
  let(:anything) { described_class.new('*/*', 1, 3) }

  it "calculates priority"
  it 'compares against another Specification' do
  end

  context '#priority' do
    it 'lower priority for media ranges' do
      expect(plain_text.priority).to eq(0.7)
      expect(any_text.priority).to eq(-9)
      expect(anything.priority).to eq(-19)
    end
  end

  context '#<=>' do
    let(:html) { described_class.new('text/html', 1, 4) }
    let(:json) { described_class.new('application/json', 1, 1) }


    it 'checks priority first' do
      expect(anything <=> json).to eq(-1)
      expect(anything <=> any_text).to eq(-1)
    end

    it 'against same priority and quality, a lower index takes precedence' do
      expect(html <=> json).to eq(-1)
    end
  end
end
