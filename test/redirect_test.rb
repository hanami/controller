require 'test_helper'

describe Lotus::Action do
  describe 'redirect' do
    it 'redirects to the given path' do
      action   = RedirectAction.new
      response = action.call({})

      response[0].must_equal(302)
      response[1].must_equal({ 'Location' => '/destination', 'Content-Type'=>'application/octet-stream; charset=utf-8' })
    end

    it 'redirects with custom status code' do
      action   = StatusRedirectAction.new
      response = action.call({})

      response[0].must_equal(301)
    end

    # Bug
    # See: https://github.com/lotus/lotus/issues/196
    it 'corces location to a ::String' do
      response = SafeStringRedirectAction.new.call({})
      response[1]['Location'].class.must_equal(::String)
    end
  end
end
