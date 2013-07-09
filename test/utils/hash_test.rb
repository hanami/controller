require 'test_helper'

describe Lotus::Utils::Hash do
  it 'acts as a Ruby standard Hash' do
    hash = Lotus::Utils::Hash.new
    hash.must_be_kind_of(::Hash)

    ::Hash.new.methods.each do |m|
      hash.must_respond_to(m)
    end
  end

  it 'holds values passed to the constructor' do
    hash = Lotus::Utils::Hash.new('foo' => 'bar')
    hash['foo'].must_equal('bar')
  end

  describe '#symbolize!' do
    it 'symbolize keys' do
      hash = Lotus::Utils::Hash.new('fub' => 'baz')
      hash.symbolize!

      hash['fub'].must_be_nil
      hash[:fub].must_equal('baz')
    end

    it 'symbolize nested hashes' do
      hash = Lotus::Utils::Hash.new('nested' => {'key' => 'value'})
      hash.symbolize!

      hash[:nested][:key].must_equal('value')
    end
  end
end
