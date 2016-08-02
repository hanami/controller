require 'test_helper'

describe Hanami::Action::BaseParams do
  before do
    @action = Test::Index.new
  end

  describe '#initialize' do
    it 'creates params without changing the raw request params' do
      env = { 'router.params' => { 'some' => { 'hash' => 'value' } } }
      @action.call(env)
      env['router.params'].must_equal({ 'some' => { 'hash' => 'value' } })
    end
  end

  describe '#valid?' do
    it 'always returns true' do
      @action.call({})
      @action.params.must_be :valid?
    end
  end
end
