RSpec.describe Hanami::Action do
  describe "#cookies" do
    it "gets cookies" do
      action = GetCookiesAction.new
      _, headers, body = action.call("HTTP_COOKIE" => "foo=bar")

      expect(action.send(:cookies)).to include(foo: "bar")
      expect(headers).to               eq("Content-Type" => "application/octet-stream; charset=utf-8")
      expect(body).to                  eq(["bar"])
    end

    it "change cookies" do
      action = ChangeCookiesAction.new
      _, headers, body = action.call("HTTP_COOKIE" => "foo=bar")

      expect(action.send(:cookies)).to include(foo: "bar")
      expect(headers).to               eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "foo=baz")
      expect(body).to                  eq(["bar"])
    end

    it "sets cookies" do
      action = SetCookiesAction.new
      _, headers, body = action.call({})

      expect(body).to    eq(["yo"])
      expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "foo=yum%21")
    end

    it "sets cookies with options" do
      tomorrow = Time.now + 60 * 60 * 24
      action   = SetCookiesWithOptionsAction.new(expires: tomorrow)
      _, headers, = action.call({})

      expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "kukki=yum%21; domain=hanamirb.org; path=/controller; expires=#{tomorrow.httpdate}; secure; HttpOnly")
    end

    it "removes cookies" do
      action = RemoveCookiesAction.new
      _, headers, = action.call("HTTP_COOKIE" => "foo=bar;rm=me")

      expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "rm=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT")
    end

    it "iterates cookies" do
      action = IterateCookiesAction.new
      *_, body = action.call("HTTP_COOKIE" => "foo=bar;hello=world")

      expect(body).to eq(["'foo' has value 'bar', 'hello' has value 'world'"])
    end

    describe "with default cookies" do
      it "gets default cookies" do
        action = GetDefaultCookiesAction.new
        action.class.configuration.cookies(domain: "hanamirb.org", path: "/controller", secure: true, httponly: true)

        _, headers, = action.call({})
        expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "bar=foo; domain=hanamirb.org; path=/controller; secure; HttpOnly")
      end

      it "overwritten cookies values are respected" do
        action = GetOverwrittenCookiesAction.new
        action.class.configuration.cookies(domain: "hanamirb.org", path: "/controller", secure: true, httponly: true)

        _, headers, = action.call({})
        expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "bar=foo; domain=hanamirb.com; path=/action")
      end
    end

    describe "with max_age option and without expires option" do
      it "automatically set expires option" do
        now = Time.now
        expect(Time).to receive(:now).at_least(2).and_return(now)

        action = GetAutomaticallyExpiresCookiesAction.new
        _, headers, = action.call({})
        max_age = 120
        expect(headers["Set-Cookie"]).to include("max-age=#{max_age}")
        expect(headers["Set-Cookie"]).to include("expires=#{(Time.now + max_age).httpdate}")
      end
    end
  end
end
