require 'test_helper'
require 'rack/test'

describe 'Sessions with cookies application' do
  include Rack::Test::Methods

  def app
    SessionWithCookies::Application.new
  end

  def response
    last_response
  end

  it 'Set-Cookie with rack.session value is sent only one time' do
    get '/', {}, 'HTTP_ACCEPT' => 'text/html'

    set_cookie_value = response.headers["Set-Cookie"]
    rack_session     = /(rack.session=.+);/i.match(set_cookie_value).captures.first.gsub("; path=/", "")

    get '/', {}, {'HTTP_ACCEPT' => 'text/html', 'Cookie' => rack_session}

    response.headers["Set-Cookie"].must_include rack_session
  end
end
