require 'test_helper'

Hanami::Action::CookieJar.class_eval do
  def include?(hash)
    key, value = *hash
    @cookies[key] == value
  end
end

describe Hanami::Action do
  describe 'cookies' do
    it 'gets cookies' do
      action   = GetCookiesAction.new
      _, headers, body = action.call({'HTTP_COOKIE' => 'foo=bar'})

      action.send(:cookies).must_include({foo: 'bar'})
      headers.must_equal({'Content-Type' => 'application/octet-stream; charset=utf-8'})
      body.must_equal ['bar']
    end

    it 'change cookies' do
      action   = ChangeCookiesAction.new
      _, headers, body = action.call({'HTTP_COOKIE' => 'foo=bar'})

      action.send(:cookies).must_include({foo: 'bar'})
      headers.must_equal({'Content-Type' => 'application/octet-stream; charset=utf-8', 'Set-Cookie' => 'foo=baz'})
      body.must_equal ['bar']
    end

    it 'sets cookies' do
      action   = SetCookiesAction.new
      _, headers, body = action.call({})

      body.must_equal(['yo'])
      headers.must_equal({'Content-Type' => 'application/octet-stream; charset=utf-8', 'Set-Cookie' => 'foo=yum%21'})
    end

    it 'sets cookies with options' do
      tomorrow = Time.now + 60 * 60 * 24
      action   = SetCookiesWithOptionsAction.new
      _, headers, _ = action.call({expires: tomorrow})

      headers.must_equal({'Content-Type' => 'application/octet-stream; charset=utf-8', 'Set-Cookie' => "kukki=yum%21; domain=hanamirb.org; path=/controller; expires=#{ tomorrow.gmtime.rfc2822 }; secure; HttpOnly"})
    end

    it 'removes cookies' do
      action   = RemoveCookiesAction.new
      _, headers, _ = action.call({'HTTP_COOKIE' => 'foo=bar;rm=me'})

      headers.must_equal({'Content-Type' => 'application/octet-stream; charset=utf-8', 'Set-Cookie' => "rm=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000"})
    end

    describe 'with default cookies' do
      it 'gets default cookies' do
        action   = GetDefaultCookiesAction.new
        action.class.configuration.cookies({
          domain: 'hanamirb.org', path: '/controller', secure: true, httponly: true
        })

        _, headers, _ = action.call({})
        headers.must_equal({'Content-Type' => 'application/octet-stream; charset=utf-8', 'Set-Cookie' => 'bar=foo; domain=hanamirb.org; path=/controller; secure; HttpOnly'})
      end

      it "overwritten cookies' values are respected" do
        action   = GetOverwrittenCookiesAction.new
        action.class.configuration.cookies({
          domain: 'hanamirb.org', path: '/controller', secure: true, httponly: true
        })

        _, headers, _ = action.call({})
        headers.must_equal({'Content-Type' => 'application/octet-stream; charset=utf-8', 'Set-Cookie' => 'bar=foo; domain=hanamirb.com; path=/action'})
      end
    end

    describe 'with max_age option and without expires option' do
      it 'automatically set expires option' do
        Time.stub :now, Time.now do
          action = GetAutomaticallyExpiresCookiesAction.new
          _, headers, _ = action.call({})
          max_age = 120
          headers["Set-Cookie"].must_include("max-age=#{max_age}")
          headers["Set-Cookie"].must_include("expires=#{(Time.now + max_age).gmtime.rfc2822}")
        end
      end
    end
  end
end
