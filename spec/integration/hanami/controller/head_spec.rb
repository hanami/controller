# frozen_string_literal: true

require "rack/test"
require "rack/utils"

RSpec.describe "HTTP HEAD" do
  include Rack::Test::Methods

  def app
    HeadTest::Application.new
  end

  def response
    last_response
  end

  it "Returns headers but an empty body " do
    head "/"
    headers = response.headers.to_a

    expect(response.status).to be(200)
    expect(response.body.to_s).to be_empty
    expect(headers).to include(["Content-Type", "application/octet-stream; charset=utf-8"])
    expect(headers).to include(%w[Content-Length 5])
  end

  it "allows to bypass restriction on custom headers" do
    get "/override"

    expect(response.status).to be(204)
    expect(response.body).to   eq("")

    headers = response.headers.to_a
    expect(headers).to include(["Last-Modified", "Fri, 27 Nov 2015 13:32:36 GMT"])
    expect(headers).to include(%w[X-Rate-Limit 4000])

    expect(headers).to_not include(%w[X-No-Pass true])
    expect(headers).to_not include(["Content-Type", "application/octet-stream; charset=utf-8"])
  end

  HTTP_TEST_STATUSES_WITHOUT_BODY.each do |code|
    describe "with: #{code}" do
      if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.key?(code)
        it "doesn't send body and default headers" do
          get "/code/#{code}"

          expect(response.status).to           be(code)
          expect(response.body).to             eq("")
          expect(response.headers.to_a).to_not include(%w[X-Frame-Options DENY])
        end

        it "doesn't send Content-Length header" do
          get "/code/#{code}"

          expect(response.status).to      be(code)
          expect(response.headers).to_not have_key("Content-Length")
        end
      else
        it "does send body and default headers" do
          get "/code/#{code}"

          expect(response.status).to           be(code)
          expect(response.body).to_not         be_empty
          expect(response.headers.to_a).to_not include(%w[X-Frame-Options DENY])
        end

        it "does send Content-Length header" do
          get "/code/#{code}"

          expect(response.status).to      be(code)
          expect(response.headers).to     have_key("Content-Length")
        end
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

        expect(response.status).to be(code)
        expect(response.headers.keys).to_not include("Content-Length")
      end

      it "doesn't send Content-Type header" do
        get "/code/#{code}"

        expect(response.status).to be(code)
        expect(response.headers.keys).to_not include("Content-Type")
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
