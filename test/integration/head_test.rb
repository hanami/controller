require 'test_helper'
require 'rack/test'

HeadRoutes = Lotus::Router.new(namespace: HeadTest) do
  get '/',           to: 'home#index'
  get '/code/:code', to: 'home#code'
  get '/cookies',    to: 'home#cookies'
end

HeadApplication = Rack::Builder.new do
  use Rack::Session::Cookie, secret: SecureRandom.hex(16)
  run HeadRoutes
end.to_app

describe 'HEAD' do
  include Rack::Test::Methods

  def app
    HeadApplication
  end

  def response
    last_response
  end

  it "doesn't send body and default headers" do
    head '/'

    response.status.must_equal(200)
    response.body.must_equal ""
    response.headers.to_a.wont_include ['X-Frame-Options','DENY']
  end

  HTTP_TEST_STATUSES_WITHOUT_BODY.each do |code|
    describe "with: #{ code }" do
      it "doesn't send body and default headers" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.body.must_equal ""
        response.headers.to_a.wont_include ['X-Frame-Options','DENY']
      end

      it "sends Allow header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers['Allow'].must_equal 'GET, HEAD'
      end

      it "sends Content-Encoding header" do
         get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers['Content-Encoding'].must_equal 'identity'
      end

      it "sends Content-Language header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers['Content-Language'].must_equal 'en'
      end

      it "doesn't send Content-Length header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers.key?('Content-Length').must_equal false
      end

      it "doesn't send Content-Type header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers.key?('Content-Type').must_equal false
      end

      it "sends Content-Location header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers['Content-Location'].must_equal 'relativeURI'
      end

      it "sends Content-MD5 header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers['Content-MD5'].must_equal 'c13367945d5d4c91047b3b50234aa7ab'
      end

      it "sends Expires header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers['Expires'].must_equal 'Thu, 01 Dec 1994 16:00:00 GMT'
      end

      it "sends Last-Modified header" do
        get "/code/#{ code }"

        response.status.must_equal(code)
        response.headers['Last-Modified'].must_equal 'Wed, 21 Jan 2015 11:32:10 GMT'
      end
    end
  end
end
