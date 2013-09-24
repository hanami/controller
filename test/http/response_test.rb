require 'test_helper'

describe Lotus::HTTP::Response do
  before do
    @action   = Object.new
    @response = Lotus::HTTP::Response.new(@action)
  end

  describe '.fabricate' do
    it 'fabricates response from serialized Rack response' do
      response = Lotus::HTTP::Response.fabricate([412, {'X-Custom' => 'true'}, ['hello!']])

      response.status.must_equal(412)
      response.header.must_equal({'X-Custom' => 'true'})
      response.body.must_equal(['hello!'])
    end

    it 'fabricates response from partial informations' do
      response = Lotus::HTTP::Response.fabricate([100])

      response.status.must_equal(100)
      response.header.must_equal({})
      response.body.must_equal([])
    end
  end

  it 'inheriths from Rack::Response' do
    @response.must_be_kind_of(::Rack::Response)
  end

  it 'exposes action' do
    @response.action.must_equal(@action)
  end

  it 'wraps body when it is set' do
    @response.body = 'hi'
    @response.body.must_equal ['hi']

    @response.body = ['hello']
    @response.body.must_equal ['hello']
  end
end
