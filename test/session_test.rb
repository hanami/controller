require 'test_helper'

describe Hanami::Action do
  describe 'session' do
    it 'captures session from Rack env' do
      action = SessionAction.new
      action.call({'rack.session' => session = { 'user_id' => '23' }})

      action.session.must_equal(session)
    end

    it 'returns empty hash when it is missing' do
      action = SessionAction.new
      action.call({})

      action.session.must_equal({})
    end

    it 'exposes session' do
      action = SessionAction.new
      action.call({'rack.session' => session = { 'foo' => 'bar' }})

      action.exposures[:session].must_equal(session)
    end

    it 'allows value access via symbolic keys' do
      action = SessionAction.new
      action.call({'rack.session' => { 'foo' => 'bar' }})

      action.session[:foo].must_equal('bar')
    end
  end
end
