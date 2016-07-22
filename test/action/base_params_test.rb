require 'test_helper'

describe Hanami::Action::BaseParams do
  before do
    @action = Test::Index.new
  end

  describe '#valid?' do
    it 'always returns true' do
      @action.call({})
      @action.params.must_be :valid?
    end
  end
end
