require 'test_helper'
require 'rack/test'

SendFileRoutes = Lotus::Router.new(namespace: SendFileTest) do
  get '/files/:id',  to: 'files#show'
  get '/code/:code', to: 'files#head_request'
end

SendFileApplication = Rack::Builder.new do
  run SendFileRoutes
end.to_app

describe 'Full stack application' do
  include Rack::Test::Methods

  def app
    SendFileApplication
  end

  describe 'if file exists, app responds 200' do
    it 'and get correct mime type for txt file' do
      get '/files/1', {}
      file = Pathname.new('test/assets/test.txt')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].to_i.must_equal file.size
      last_response.headers['Content-Type'].must_equal 'text/plain'
    end

    it 'and get correct mime type for png file' do
      get '/files/2', {}
      file = Pathname.new('test/assets/lotus.png')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].to_i.must_equal file.size
      last_response.headers['Content-Type'].must_equal 'image/png'
    end
  end

  describe "if file doesn't exist" do
    it "responds 404" do
      get '/files/100', {}

      last_response.status.must_equal 404
    end
  end

  HTTP_TEST_STATUSES_WITHOUT_BODY.each do |code|
    describe "with: #{ code }" do
      it "head request doesn't send file" do
        head "/code/#{code}"

        last_response.status.must_equal(code)
      end
    end
  end

  describe 'forced Content-Type' do
    it 'must return correct Content-Type' do
      get '/files/2', {}, 'HTTP_ACCEPT' => 'text/html'
      file = Pathname.new('test/assets/lotus.png')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].to_i.must_equal file.size
      last_response.headers['Content-Type'].must_equal 'image/png'
    end
  end

  describe 'conditional get request' do
    it "shouldn't send file" do
      get '/files/1', {}, 'HTTP_ACCEPT' => 'text/html', 'HTTP_IF_MODIFIED_SINCE' => Time.now.gmtime.rfc2822
      file = Pathname.new('test/assets/test.txt')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].must_equal nil
      last_response.headers['Content-Type'].must_equal 'text/html; charset=utf-8'
    end
  end

  describe 'bytes range' do
    it "shouldn't send file" do
      get '/files/1', {}, 'HTTP_RANGE' => 'bytes=1'
      file = Pathname.new('test/assets/test.txt')

      last_response.status.must_equal 200
      last_response.headers['Content-Length'].must_equal nil
      last_response.headers['Content-Type'].must_equal 'application/octet-stream; charset=utf-8'
    end
  end
end
