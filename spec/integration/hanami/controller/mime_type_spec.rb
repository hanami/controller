RSpec.describe 'MIME Type' do
  describe "Content type" do
    let(:app) { Rack::MockRequest.new(Mimes::Application.new) }

    it 'fallbacks to the default "Content-Type" header when the request is lacking of this information' do
      response = app.get("/")
      expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
      expect(response.body).to                    eq("all")
    end

    it "fallbacks to the default format and charset, set in the configuration" do
      response = app.get("/configuration")
      expect(response.headers["Content-Type"]).to eq("text/html; charset=ISO-8859-1")
      expect(response.body).to                    eq("html")
    end

    it 'returns the specified "Content-Type" header' do
      response = app.get("/custom")
      expect(response.headers["Content-Type"]).to eq("application/xml; charset=utf-8")
      expect(response.body).to                    eq("xml")
    end

    it "returns the custom charser header" do
      response = app.get("/latin")
      expect(response.headers["Content-Type"]).to eq("text/html; charset=latin1")
      expect(response.body).to                    eq("html")
    end

    it "uses default_response_format if set in the configuration regardless of request format" do
      response = app.get("/response")
      expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      expect(response.body).to                    eq("html")
    end

    it "allows to override default_response_format" do
      response = app.get("/overwritten_format")
      expect(response.headers["Content-Type"]).to eq("application/xml; charset=utf-8")
    end

    # FIXME: Review if this test must be in place
    xit 'does not produce a "Content-Type" header when the request has a 204 No Content status' do
      response = app.get("/nocontent")
      expect(response.headers).to_not have_key("Content-Type")
      expect(response.body).to        eq("")
    end

    context "when Accept is sent" do
      it 'sets "Content-Type" header according to wildcard value' do
        response = app.get("/", "HTTP_ACCEPT" => "*/*")
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
        expect(response.body).to                    eq("all")
      end

      it 'sets "Content-Type" header according to exact value' do
        response = app.get("/custom_from_accept", "HTTP_ACCEPT" => "application/custom")
        expect(response.headers["Content-Type"]).to eq("application/custom; charset=utf-8")
        expect(response.body).to                    eq("custom")
      end

      it 'sets "Content-Type" header according to weighted value' do
        response = app.get("/custom_from_accept", "HTTP_ACCEPT" => "application/custom;q=0.9,application/json;q=0.5")
        expect(response.headers["Content-Type"]).to eq("application/custom; charset=utf-8")
        expect(response.body).to                    eq("custom")
      end

      it 'sets "Content-Type" header according to weighted, unordered value' do
        response = app.get("/custom_from_accept", "HTTP_ACCEPT" => "application/custom;q=0.1, application/json;q=0.5")
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(response.body).to                    eq("json")
      end

      it 'sets "Content-Type" header according to exact and weighted value' do
        response = app.get("/", "HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response.body).to                    eq("html")
      end

      it 'sets "Content-Type" header according to quality scale value' do
        response = app.get("/", "HTTP_ACCEPT" => "application/json;q=0.6,application/xml;q=0.9,*/*;q=0.8")
        expect(response.headers["Content-Type"]).to eq("application/xml; charset=utf-8")
        expect(response.body).to                    eq("xml")
      end
    end
  end

  describe "Accept" do
    let(:app)      { Rack::MockRequest.new(Mimes::Application.new) }
    let(:response) { app.get("/accept", "HTTP_ACCEPT" => accept) }

    context "when Accept is missing" do
      let(:accept) { nil }

      it "accepts all" do
        expect(response.headers["X-AcceptDefault"]).to eq("true")
        expect(response.headers["X-AcceptHtml"]).to    eq("true")
        expect(response.headers["X-AcceptXml"]).to     eq("true")
        expect(response.headers["X-AcceptJson"]).to    eq("true")
        expect(response.body).to                       eq("all")
      end
    end

    context "when Accept is sent" do
      context 'when "*/*"' do
        let(:accept) { "*/*" }

        it "accepts all" do
          expect(response.headers["X-AcceptDefault"]).to eq("true")
          expect(response.headers["X-AcceptHtml"]).to    eq("true")
          expect(response.headers["X-AcceptXml"]).to     eq("true")
          expect(response.headers["X-AcceptJson"]).to    eq("true")
          expect(response.body).to                       eq("all")
        end
      end

      context 'when "text/html"' do
        let(:accept) { "text/html" }

        it "accepts selected mime types" do
          expect(response.headers["X-AcceptDefault"]).to eq("false")
          expect(response.headers["X-AcceptHtml"]).to    eq("true")
          expect(response.headers["X-AcceptXml"]).to     eq("false")
          expect(response.headers["X-AcceptJson"]).to    eq("false")
          expect(response.body).to                       eq("html")
        end
      end

      context "when weighted" do
        let(:accept) { "text/html,application/xhtml+xml,application/xml;q=0.9" }

        it "accepts selected mime types" do
          expect(response.headers["X-AcceptDefault"]).to eq("false")
          expect(response.headers["X-AcceptHtml"]).to    eq("true")
          expect(response.headers["X-AcceptXml"]).to     eq("true")
          expect(response.headers["X-AcceptJson"]).to    eq("false")
          expect(response.body).to                       eq("html")
        end
      end
    end
  end

  describe "Restricted Accept" do
    let(:app)      { Rack::MockRequest.new(Mimes::Application.new) }
    let(:response) { app.get("/restricted", "HTTP_ACCEPT" => accept) }

    context "when Accept is missing" do
      let(:accept) { nil }

      it "returns the mime type according to the application defined policy" do
        expect(response.status).to be(200)
        expect(response.body).to   eq("all")
      end
    end

    context "when Accept is sent" do
      context 'when "*/*"' do
        let(:accept) { "*/*" }

        it "returns the mime type according to the application defined policy" do
          expect(response.status).to be(200)
          expect(response.body).to   eq("all")
        end
      end

      context "when accepted" do
        let(:accept) { "text/html" }

        it "accepts selected MIME Types" do
          expect(response.status).to be(200)
          expect(response.body).to   eq("html")
        end
      end

      context "when custom MIME Type" do
        let(:accept) { "application/custom" }

        it "accepts selected mime types" do
          expect(response.status).to be(200)
          expect(response.body).to   eq("custom")
        end
      end

      context "when not accepted" do
        let(:accept) { "application/xml" }

        it "accepts selected MIME Types" do
          expect(response.status).to be(406)
        end
      end

      context "when weighted" do
        context "with an accepted format as first choice" do
          let(:accept) { "text/html,application/xhtml+xml,application/xml;q=0.9" }

          it "accepts selected mime types" do
            expect(response.status).to be(200)
            expect(response.body).to   eq("html")
          end
        end

        context "with an accepted format as last choice" do
          let(:accept) { "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,*/*;q=0.5" }

          it "accepts selected mime types" do
            expect(response.status).to be(200)
            expect(response.body).to   eq("html")
          end
        end
      end
    end
  end
end
