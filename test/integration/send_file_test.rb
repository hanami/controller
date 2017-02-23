require 'test_helper'
require 'rack/test'

SendFileRoutes = Hanami::Router.new(namespace: SendFileTest) do
  get '/files/flow',          to: 'files#flow'
  get '/files/unsafe',        to: 'files#unsafe'
  get '/files/:id(.:format)', to: 'files#show'
  get '/files/(*glob)',       to: 'files#glob'
end

SendFileApplication = Rack::Builder.new do
  run SendFileRoutes
end.to_app

describe 'Full stack application' do
  include Rack::Test::Methods

  def app
    SendFileApplication
  end

  describe 'send files from anywhere in the system' do
    it 'responds 200 when the file exists' do
      get '/files/unsafe', {}
      file = Pathname.new('Gemfile')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].to_i.must_equal file.size
      last_response.headers['Content-Type'].must_equal 'text/plain'
      last_response.body.size.must_equal(file.size)
    end
  end

  describe 'when file exists, app responds 200' do
    it 'sets Content-Type according to file type' do
      get '/files/1', {}
      file = Pathname.new('test/assets/test.txt')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].to_i.must_equal file.size
      last_response.headers['Content-Type'].must_equal 'text/plain'
      last_response.body.size.must_equal(file.size)
    end

    it 'sets Content-Type according to file type (ignoring HTTP_ACCEPT)' do
      get '/files/2', {}, 'HTTP_ACCEPT' => 'text/html'
      file = Pathname.new('test/assets/hanami.png')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].to_i.must_equal file.size
      last_response.headers['Content-Type'].must_equal 'image/png'
      last_response.body.size.must_equal(file.size)
    end

    it "doesn't send file in case of HEAD request" do
      head '/files/1', {}

      last_response.status.must_equal 200
      last_response.headers.key?('Content-Length').must_equal false
      last_response.headers.key?('Content-Type').must_equal false
      last_response.body.must_be :empty?
    end

    it "doesn't send file outside of public directory" do
      get '/files/3', {}

      last_response.status.must_equal 404
    end
  end

  describe "if file doesn't exist" do
    it "responds 404" do
      get '/files/100', {}

      last_response.status.must_equal 404
      last_response.body.must_equal "Not Found"
    end
  end

  describe 'conditional get request' do
    it "shouldn't send file" do
      if_modified_since = File.mtime('test/assets/test.txt').httpdate
      get '/files/1', {}, 'HTTP_ACCEPT' => 'text/html', 'HTTP_IF_MODIFIED_SINCE' => if_modified_since

      last_response.status.must_equal 304
      last_response.headers.key?('Content-Length').must_equal false
      last_response.headers.key?('Content-Type').must_equal false
      last_response.body.must_be :empty?
    end
  end

  describe 'bytes range' do
    it "sends ranged contents" do
      get '/files/1', {}, 'HTTP_RANGE' => 'bytes=5-13'

      last_response.status.must_equal 206
      last_response.headers['Content-Length'].must_equal '9'
      last_response.headers['Content-Range'].must_equal  'bytes 5-13/69'
      last_response.body.must_equal "Text File"
    end
  end

  it "interrupts the control flow" do
    get '/files/flow', {}
    last_response.status.must_equal 200
  end
end
