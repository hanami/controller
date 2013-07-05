require 'test_helper'

describe Lotus::Action do
  describe 'cookies' do
    it 'gets cookies' do
      action   = GetCookiesAction.new
      response = action.call({'HTTP_COOKIE' => 'foo=bar'})

      action.send(:cookies).must_equal({foo: 'bar'})
      response.headers.must_equal({'Set-Cookie' => 'foo=bar'})
    end

    it 'sets cookies' do
      action   = SetCookiesAction.new
      response = action.call({})

      response.body.must_equal(['yo'])
      response.headers.must_equal({'Set-Cookie' => 'foo=yum%21'})
    end

    it 'sets cookies with options' do
      tomorrow = Time.now + 60 * 60 * 24
      action   = SetCookiesWithOptionsAction.new
      response = action.call({expires: tomorrow})

      response.headers.must_equal({'Set-Cookie' => "kukki=yum%21; domain=lotusrb.org; path=/controller; expires=#{ tomorrow.gmtime.rfc2822 }; secure; HttpOnly"})
    end

    it 'removes cookies' do
      action   = RemoveCookiesAction.new
      response = action.call({'HTTP_COOKIE' => 'foo=bar;rm=me'})

      response.headers.must_equal({'Set-Cookie' => "foo=bar\nrm=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000"})
    end
  end
end
