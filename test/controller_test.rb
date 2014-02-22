require 'test_helper'

describe Lotus::Controller do
  describe '.action' do
    it 'creates an action for the given name' do
      action = TestController::Index.new
      action.call({name: 'test'})
      action.xyz.must_equal 'test'
    end

    it "raises an error when the given name isn't a valid Ruby identifier" do
      -> {
        class Controller
          include Lotus::Controller

          action 12 do
            def call(params)
            end
          end
        end
      }.must_raise TypeError
    end
  end
end
