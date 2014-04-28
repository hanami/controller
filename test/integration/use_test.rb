require 'test_helper'

describe 'Rack middleware integration' do
  describe '.use' do
    it 'uses the specified Rack middleware' do
      response = Rack::MockRequest.new(UseAction.new).get('/')
      status, headers, _ = response

      status.must_equal 200
      headers['X-Middleware'].must_equal 'OK'
    end
  end
end
