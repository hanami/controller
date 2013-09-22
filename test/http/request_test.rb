require 'test_helper'

describe Lotus::HTTP::Request do
  it 'inheriths from Rack::Request' do
    Lotus::HTTP::Request.new({}).must_be_kind_of(::Rack::Request)
  end

  describe '#accept' do
    it 'returns "*/*" when HTTP_ACCEPT is not set' do
      request = Lotus::HTTP::Request.new({})
      request.accept.must_equal '*/*'
    end

    it 'returns "*/*" when HTTP_ACCEPT is "*/*"' do
      request = Lotus::HTTP::Request.new({'HTTP_ACCEPT' => '*/*'})
      request.accept.must_equal '*/*'
    end

    it 'returns "text/plain" when HTTP_ACCEPT is "text/plain"' do
      request = Lotus::HTTP::Request.new({'HTTP_ACCEPT' => 'text/plain'})
      request.accept.must_equal 'text/plain'
    end

    it 'returns "application/xml" when HTTP_ACCEPT is "application/xml,application/xhtml+xml"' do
      request = Lotus::HTTP::Request.new({'HTTP_ACCEPT' => 'application/xml,application/xhtml+xml'})
      request.accept.must_equal 'application/xml'
    end

    it 'returns "text/html" when HTTP_ACCEPT is "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"' do
      request = Lotus::HTTP::Request.new({'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'})
      request.accept.must_equal 'text/html'
    end

    # it 'returns "text/html" when HTTP_ACCEPT is "application/xml,application/xhtml+xml;q=0.8,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.6"' do
    #   request = Lotus::HTTP::Request.new({'HTTP_ACCEPT' => 'application/xml,application/xhtml+xml;q=0.8,text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.6'})
    #   request.accept.must_equal 'text/html'
    # end
  end
end
