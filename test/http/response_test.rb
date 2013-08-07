require 'test_helper'

describe Lotus::HTTP::Response do
  before do
    @action   = Object.new
    @response = Lotus::HTTP::Response.new(@action)
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
