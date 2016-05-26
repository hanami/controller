require 'test_helper'
require 'hanami/action/request'

describe Hanami::Action::Request do
  def build_request(attributes = {})
    url = 'http://example.com/foo?q=bar'
    env = Rack::MockRequest.env_for(url, attributes)
    Hanami::Action::Request.new(env)
  end

  describe '#body' do
    it 'exposes the raw body of the request' do
      body    = build_request(input: 'This is the body').body
      content = body.read

      content.must_equal('This is the body')
    end
  end

  describe '#script_name' do
    it 'gets the script name of a mounted app' do
      build_request(script_name: '/app').script_name.must_equal('/app')
    end
  end

  describe '#path_info' do
    it 'gets the requested path' do
      build_request.path_info.must_equal('/foo')
    end
  end

  describe '#request_method' do
    it 'gets the request method' do
      build_request.request_method.must_equal('GET')
    end
  end

  describe '#query_string' do
    it 'gets the raw query string' do
      build_request.query_string.must_equal('q=bar')
    end
  end

  describe '#content_length' do
    it 'gets the length of the body' do
      build_request(input: '123').content_length.must_equal('3')
    end
  end

  describe '#scheme' do
    it 'gets the request scheme' do
      build_request.scheme.must_equal('http')
    end
  end

  describe '#ssl?' do
    it 'answers if ssl is used' do
      build_request.ssl?.must_equal false
    end
  end

  describe '#host_with_port' do
    it 'gets host and port' do
      build_request.host_with_port.must_equal('example.com:80')
    end
  end

  describe '#port' do
    it 'gets the port' do
      build_request.port.must_equal(80)
    end
  end

  describe '#host' do
    it 'gets the host' do
      build_request.host.must_equal('example.com')
    end
  end

  describe 'request method boolean methods' do
    it 'answers correctly' do
      request = build_request
      %i(delete? head? options? patch? post? put? trace? xhr?).each do |method|
        request.send(method).must_equal(false)
      end
      request.get?.must_equal(true)
    end
  end

  describe '#referer' do
    it 'gets the HTTP_REFERER' do
      request = build_request('HTTP_REFERER' => 'http://host.com/path')
      request.referer.must_equal('http://host.com/path')
    end
  end

  describe '#user_agent' do
    it 'gets the value of HTTP_USER_AGENT' do
      request = build_request('HTTP_USER_AGENT' => 'Chrome')
      request.user_agent.must_equal('Chrome')
    end
  end

  describe '#base_url' do
    it 'gets the base url' do
      build_request.base_url.must_equal('http://example.com')
    end
  end

  describe '#url' do
    it 'gets the full request url' do
      build_request.url.must_equal('http://example.com/foo?q=bar')
    end
  end

  describe '#path' do
    it 'gets the request path' do
      build_request.path.must_equal('/foo')
    end
  end

  describe '#fullpath' do
    it 'gets the path and query' do
      build_request.fullpath.must_equal('/foo?q=bar')
    end
  end

  describe '#accept_encoding' do
    it 'gets the value and quality of accepted encodings' do
      request = build_request('HTTP_ACCEPT_ENCODING' => 'gzip, deflate;q=0.6')
      request.accept_encoding.must_equal([['gzip', 1], ['deflate', 0.6]])
    end
  end

  describe '#accept_language' do
    it 'gets the value and quality of accepted languages' do
      request = build_request('HTTP_ACCEPT_LANGUAGE' => 'da, en;q=0.6')
      request.accept_language.must_equal([['da', 1], ['en', 0.6]])
    end
  end

  describe '#ip' do
    it 'gets the request ip' do
      request = build_request('REMOTE_ADDR' => '123.123.123.123')
      request.ip.must_equal('123.123.123.123')
    end
  end

  describe 'request methods that are implemented elsewhere' do
    it 'should reject with a NotImplementedError' do
      methods = %i(
        content_type
        session
        cookies
        params
        update_param
        delete_param
        []
        []=
        values_at
      )
      request = Hanami::Action::Request.new({})
      methods.each do |method|
        proc { request.send(method) }.must_raise(NotImplementedError)
      end
    end
  end
end
