require 'test_helper'

describe Lotus::Action do
  describe 'redirect' do
    it 'redirects to the given path' do
      action   = RedirectAction.new
      response = action.call({})

      response[0].must_equal(302)
      response[1].must_equal({ 'Content-Type' => 'application/octet-stream; charset=utf-8', 'Location' => '/destination' })
    end

    it 'redirects with custom status code' do
      action   = StatusRedirectAction.new
      response = action.call({})

      response[0].must_equal(301)
    end
  end
end
