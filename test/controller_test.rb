require 'test_helper'

describe Lotus::Controller do
  describe '.action' do
    it 'creates an action for the given name' do
      action = TestController::Index.new
      action.call({name: 'test'})
      action.xyz.must_equal 'test'
    end
  end
end
