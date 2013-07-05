require 'test_helper'
require 'rack'

describe Lotus::Action::Params do
  describe 'when Lotus::Router is avaliable' do
    before do
      module Lotus
        const_set('Router', Class.new) if not defined?(Router)
      end

      # Reload the class
      load File.dirname(__FILE__) + '/../../lib/lotus/action/params.rb'

      class RouterAction
        include Lotus::Action

        def call(params)
          self.body = params.inspect
        end
      end
    end

    it 'accepts params from "router.params"' do
      action   = RouterAction.new
      response = action.call({ 'router.params' => {id: '23'} })

      response.body.must_equal ["{:id=>\"23\"}"]
    end

    it 'accepts params as they are, for testing purposes' do
      action   = RouterAction.new
      response = action.call({id: '23'})

      response.body.must_equal ["{:id=>\"23\"}"]
    end
  end

  describe 'when plain Rack app' do
    before do
      module Lotus
        remove_const('Router') if defined?(Router)
      end

      # Reload the class
      load File.dirname(__FILE__) + '/../../lib/lotus/action/params.rb'

      class RackAction
        include Lotus::Action

        def call(params)
          self.body = params.inspect
        end
      end
    end

    it 'accepts params from "rack.input"' do
      response = Rack::MockRequest.new(RackAction.new).get("?id=23")
      response.body.must_match "{:id=>\"23\"}"
    end
  end

  it 'is frozen' do
    params  = Lotus::Action::Params.new({id: '23'})

    -> { params.delete(:id) }.must_raise(RuntimeError)
  end
end
