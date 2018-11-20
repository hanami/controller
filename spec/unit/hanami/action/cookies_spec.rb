RSpec.describe Hanami::Action do
  describe "#cookies" do
    it "gets cookies" do
      action = GetCookiesAction.new(configuration: configuration)
      response = action.call("HTTP_COOKIE" => "foo=bar")

      expect(response.cookies).to include(foo: "bar")
      expect(response.headers).to eq("Content-Length" => "3", "Content-Type" => "application/octet-stream; charset=utf-8")
      expect(response.body).to    eq(["bar"])
    end

    it "change cookies" do
      action = ChangeCookiesAction.new(configuration: configuration)
      response = action.call("HTTP_COOKIE" => "foo=bar")

      expect(response.cookies).to include(foo: "bar")
      expect(response.headers).to eq("Content-Length" => "3", "Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "foo=baz")
      expect(response.body).to    eq(["bar"])
    end

    it "sets cookies" do
      action = SetCookiesAction.new(configuration: configuration)
      response = action.call({})

      expect(response.body).to    eq(["yo"])
      expect(response.headers).to eq("Content-Length" => "2", "Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "foo=yum%21")
    end

    it "sets cookies with options" do
      tomorrow = Time.now + 60 * 60 * 24
      action   = SetCookiesWithOptionsAction.new(configuration: configuration, expires: tomorrow)
      response = action.call({})

      expect(response.headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "kukki=yum%21; domain=hanamirb.org; path=/controller; expires=#{tomorrow.gmtime.rfc2822}; secure; HttpOnly")
    end

    it "removes cookies" do
      action = RemoveCookiesAction.new(configuration: configuration)
      response = action.call("HTTP_COOKIE" => "foo=bar;rm=me")

      expect(response.headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "rm=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000")
    end

    it "iterates cookies" do
      action = IterateCookiesAction.new(configuration: configuration)
      response = action.call("HTTP_COOKIE" => "foo=bar;hello=world")

      expect(response.body).to eq(["'foo' has value 'bar', 'hello' has value 'world'"])
    end

    describe "with default cookies" do
      let(:configuration) do
        Hanami::Controller::Configuration.new do |config|
          config.cookies = { domain: "hanamirb.org", path: "/controller", secure: true, httponly: true }
        end
      end

      it "gets default cookies" do
        action = GetDefaultCookiesAction.new(configuration: configuration)

        response = action.call({})
        expect(response.headers).to eq("Content-Length" => "0", "Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "bar=foo; domain=hanamirb.org; path=/controller; secure; HttpOnly")
      end

      it "overwritten cookies values are respected" do
        action = GetOverwrittenCookiesAction.new(configuration: configuration)

        response = action.call({})
        expect(response.headers).to eq("Content-Length" => "0", "Content-Type" => "application/octet-stream; charset=utf-8", "Set-Cookie" => "bar=foo; domain=hanamirb.com; path=/action")
      end
    end

    describe "with max_age option and without expires option" do
      it "automatically set expires option" do
        now = Time.now
        expect(Time).to receive(:now).at_least(2).and_return(now)

        action = GetAutomaticallyExpiresCookiesAction.new(configuration: configuration)
        response = action.call({})
        max_age = 120
        expect(response.headers["Set-Cookie"]).to include("max-age=#{max_age}")
        expect(response.headers["Set-Cookie"]).to include("expires=#{(Time.now + max_age).gmtime.rfc2822}")
      end
    end
  end
end
