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
end
