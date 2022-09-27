# frozen_string_literal: true

require "rack/test"

RSpec.describe "Flash application" do
  include Rack::Test::Methods

  def app
    Flash::Application.new
  end

  it "doesn't return empty? true after setting flash and using redirect" do
    get "/"
    follow_redirect!

    expect(last_response.body).to match(/{:hello=>"world"}/)
    expect(last_response.body).to match(/flash_empty: false/)
  end

  it "allows to access kept data after redirect" do
    post "/", {}
    follow_redirect!

    expect(last_response.body).to match(/world/)
  end

  describe "#each" do
    it "iterates through data even after redirect" do
      get "/each_redirect"
      follow_redirect!

      expect(last_response.body).to match(/flash_each: \[\[:hello, "world"\]\]/)
    end
  end

  describe "#map" do
    it "iterates through data even after redirect" do
      get "/map_redirect"
      follow_redirect!

      expect(last_response.body).to match(/flash_map: \[\[:hello, "world"\]\]/)
    end
  end
end
