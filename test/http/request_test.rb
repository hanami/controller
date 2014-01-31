require 'test_helper'

describe Lotus::HTTP::Request do
  it 'inheriths from Rack::Request' do
    Lotus::HTTP::Request.new({}).must_be_kind_of(::Rack::Request)
  end
end
