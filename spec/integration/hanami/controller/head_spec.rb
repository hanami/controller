require 'rack/test'

HeadRoutes = Hanami::Router.new(namespace: HeadTest) do
  get '/',           to: 'home#index'
  get '/code/:code', to: 'home#code'
  get '/override',   to: 'home#override'
end

HeadApplication = Rack::Builder.new do
  use Rack::Session::Cookie, secret: SecureRandom.hex(16)
  run HeadRoutes
end.to_app

RSpec.describe "HTTP HEAD" do
  include Rack::Test::Methods

  def app
    HeadApplication
  end

  def response
    last_response
  end

  it "doesn't send body and default headers" do
    head "/"

    expect(response.status).to be(200)
    expect(response.body).to   eq("")
    expect(response.headers.to_a).to_not include(["X-Frame-Options", "DENY"])
  end

  it "allows to bypass restriction on custom headers" do
    get "/override"

    expect(response.status).to be(204)
    expect(response.body).to   eq("")

    headers = response.headers.to_a
    expect(headers).to include(["Last-Modified", "Fri, 27 Nov 2015 13:32:36 GMT"])
    expect(headers).to include(["X-Rate-Limit", "4000"])

    expect(headers).to_not include(["X-No-Pass",    "true"])
    expect(headers).to_not include(["Content-Type", "application/octet-stream; charset=utf-8"])
  end

  HTTP_TEST_STATUSES_WITHOUT_BODY.each do |code|
    describe "with: #{code}" do
      it "doesn't send body and default headers" do
        get "/code/#{code}"

        expect(response.status).to           be(code)
        expect(response.body).to             eq("")
        expect(response.headers.to_a).to_not include(["X-Frame-Options", "DENY"])
      end

      it "sends Allow header" do
        get "/code/#{code}"

        expect(response.status).to           be(code)
        expect(response.headers["Allow"]).to eq("GET, HEAD")
      end

      it "sends Content-Encoding header" do
        get "/code/#{code}"

        expect(response.status).to                      be(code)
        expect(response.headers["Content-Encoding"]).to eq("identity")
      end

      it "sends Content-Language header" do
        get "/code/#{code}"

        expect(response.status).to                      be(code)
        expect(response.headers["Content-Language"]).to eq("en")
      end

      it "doesn't send Content-Length header" do
        get "/code/#{code}"

        expect(response.status).to      be(code)
        expect(response.headers).to_not have_key("Content-Length")
      end

      it "doesn't send Content-Type header" do
        get "/code/#{code}"

        expect(response.status).to      be(code)
        expect(response.headers).to_not have_key("Content-Type")
      end

      it "sends Content-Location header" do
        get "/code/#{code}"

        expect(response.status).to                      be(code)
        expect(response.headers["Content-Location"]).to eq("relativeURI")
      end

      it "sends Content-MD5 header" do
        get "/code/#{code}"

        expect(response.status).to                 be(code)
        expect(response.headers["Content-MD5"]).to eq("c13367945d5d4c91047b3b50234aa7ab")
      end

      it "sends Expires header" do
        get "/code/#{code}"

        expect(response.status).to             be(code)
        expect(response.headers["Expires"]).to eq("Thu, 01 Dec 1994 16:00:00 GMT")
      end

      it "sends Last-Modified header" do
        get "/code/#{code}"

        expect(response.status).to                   be(code)
        expect(response.headers["Last-Modified"]).to eq("Wed, 21 Jan 2015 11:32:10 GMT")
      end
    end
  end
end
