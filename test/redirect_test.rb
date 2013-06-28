require 'test_helper'

describe Lotus::Action do
  describe 'redirect' do
    it 'redirects to the given path' do
      action = RedirectAction.new
      status, headers, _ = *action.call({})

      status.must_equal(302)
      headers.must_equal({ 'Location' => '/destination' })
    end

    it 'redirects with custom status code' do
      action    = StatusRedirectAction.new
      status, _ = *action.call({})

      status.must_equal(301)
    end
  end
end
