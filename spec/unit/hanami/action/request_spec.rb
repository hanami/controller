# frozen_string_literal: true

RSpec.describe Hanami::Action::Request do
  describe "#body" do
    it "exposes the raw body of the request" do
      body    = build_request(input: "This is the body").body
      content = body.read

      expect(content).to eq("This is the body")
    end
  end

  describe "#script_name" do
    it "gets the script name of a mounted app" do
      expect(build_request(script_name: "/app").script_name).to eq("/app")
    end
  end

  describe "#path_info" do
    it "gets the requested path" do
      expect(build_request.path_info).to eq("/foo")
    end
  end

  describe "#request_method" do
    it "gets the request method" do
      expect(build_request.request_method).to eq("GET")
    end
  end

  describe "#query_string" do
    it "gets the raw query string" do
      expect(build_request.query_string).to eq("q=bar")
    end
  end

  describe "#content_length" do
    it "gets the length of the body" do
      expect(build_request(input: "123").content_length).to eq("3")
    end
  end

  describe "#scheme" do
    it "gets the request scheme" do
      expect(build_request.scheme).to eq("http")
    end
  end

  describe "#ssl?" do
    it "answers if ssl is used" do
      expect(build_request.ssl?).to be(false)
    end
  end

  describe "#host_with_port" do
    context "standard HTTP port" do
      it "gets host only" do
        expect(build_request.host_with_port).to eq("example.com")
      end
    end

    context "non-standard port" do
      it "gets host and port" do
        request = described_class.new(
          env: Rack::MockRequest.env_for("http://example.com:81/foo?q=bar", {}),
          params: {}
        )
        expect(request.host_with_port).to eq("example.com:81")
      end
    end
  end

  describe "#port" do
    it "gets the port" do
      expect(build_request.port).to be(80)
    end
  end

  describe "#host" do
    it "gets the host" do
      expect(build_request.host).to eq("example.com")
    end
  end

  describe "request method boolean methods" do
    it "answers correctly" do
      request = build_request
      %i[delete? head? options? patch? post? put? trace? xhr?].each do |method|
        expect(request.send(method)).to be(false)
      end
      expect(request.get?).to be(true)
    end
  end

  describe "#referer" do
    it "gets the HTTP_REFERER" do
      request = build_request("HTTP_REFERER" => "http://host.com/path")
      expect(request.referer).to eq("http://host.com/path")
    end
  end

  describe "#user_agent" do
    it "gets the value of HTTP_USER_AGENT" do
      request = build_request("HTTP_USER_AGENT" => "Chrome")
      expect(request.user_agent).to eq("Chrome")
    end
  end

  describe "#base_url" do
    it "gets the base url" do
      expect(build_request.base_url).to eq("http://example.com")
    end
  end

  describe "#url" do
    it "gets the full request url" do
      expect(build_request.url).to eq("http://example.com/foo?q=bar")
    end
  end

  describe "#path" do
    it "gets the request path" do
      expect(build_request.path).to eq("/foo")
    end
  end

  describe "#fullpath" do
    it "gets the path and query" do
      expect(build_request.fullpath).to eq("/foo?q=bar")
    end
  end

  describe "#accept_encoding" do
    it "gets the value and quality of accepted encodings" do
      request = build_request("HTTP_ACCEPT_ENCODING" => "gzip, deflate;q=0.6")
      expect(request.accept_encoding).to eq([["gzip", 1], ["deflate", 0.6]])
    end
  end

  describe "#accept_language" do
    it "gets the value and quality of accepted languages" do
      request = build_request("HTTP_ACCEPT_LANGUAGE" => "da, en;q=0.6")
      expect(request.accept_language).to eq([["da", 1], ["en", 0.6]])
    end
  end

  describe "#ip" do
    it "gets the request ip" do
      request = build_request("REMOTE_ADDR" => "123.123.123.123")
      expect(request.ip).to eq("123.123.123.123")
    end
  end

  private

  def build_request(attributes = {})
    url = attributes.delete("url") || "http://example.com/foo?q=bar"
    env = Rack::MockRequest.env_for(url, attributes)
    described_class.new(env: env, params: {})
  end
end
