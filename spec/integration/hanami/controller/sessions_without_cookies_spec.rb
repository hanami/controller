require "rack/test"

RSpec.describe "Sessions without cookies application" do
  include Rack::Test::Methods

  let(:app) { SessionsWithoutCookies::Application.new }

  def response
    last_response
  end

  it "Set-Cookie with rack.session value is sent only one time" do
    get "/", {}, "HTTP_ACCEPT" => "text/html"

    set_cookie_value = response.headers["Set-Cookie"]
    rack_session = /(rack.session=.+);/i.match(set_cookie_value).captures.first.gsub("; path=/", "")

    get "/", {}, "HTTP_ACCEPT" => "text/html", "Cookie" => rack_session

    expect(response.headers).to_not have_key("Set-Cookie")
  end
end
