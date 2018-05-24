RSpec.describe 'MIME Type' do
  describe "Content type" do
    let(:app) { Rack::MockRequest.new(Mimes::Application.new) }

    it 'fallbacks to the default "Content-Type" header when the request is lacking of this information' do
      response = app.get("/")
      expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
      expect(response.body).to                    eq("all")
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

    context 'when ACCEPT header is set and no accept macro is use' do
      it 'sets "Content-Type" header according to wildcard value' do
        response = app.get("/", "HTTP_ACCEPT" => "*/*")
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
        expect(response.body).to                    eq("all")
      end
    end

    context "when no ACCEPT or Content-Type are sent but there is a restriction using the accept macro" do
      it 'sets the status to 406' do
        response = app.get("/custom_from_accept")
        expect(response.status).to eq 406
      end
    end

    context "when Content-Type are sent and there is a restriction using the accept macro" do
      it 'sets "Content-Type" to fallback' do
        response = app.get("/custom_from_accept", "Content-Type" => "application/custom")
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
        expect(response.body).to                    eq("all")
      end

      it 'sets status to 406 if Content-Type do not match' do
        response = app.get("/custom_from_accept", "Content-Type" => "application/xml")
        expect(response.status).to eq(406)
      end
    end

    context "when ACCEPT and Content-Type are sent and we use the accept macro" do
      it 'sets "Content-Type" header according to exact value' do
        response = app.get("/custom_from_accept", "HTTP_ACCEPT" => "application/custom", "Content-Type" => "application/custom")
        expect(response.headers["Content-Type"]).to eq("application/custom; charset=utf-8")
        expect(response.body).to                    eq("custom")
      end

      it 'sets "Content-Type" header according to weighted value' do
        response = app.get("/custom_from_accept", "HTTP_ACCEPT" => "application/custom;q=0.9,application/json;q=0.5", "Content-Type" => "application/custom")
        expect(response.headers["Content-Type"]).to eq("application/custom; charset=utf-8")
        expect(response.body).to                    eq("custom")
      end

      it 'sets "Content-Type" header according to weighted, unordered value' do
        response = app.get("/custom_from_accept", "HTTP_ACCEPT" => "application/custom;q=0.1, application/json;q=0.5", "Content-Type" => "application/json")
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(response.body).to                    eq("json")
      end
    end

    context "when ACCEPT and Content-Type are send and there are no restriction using accept macro" do
      it 'sets "Content-Type" header according to exact and weighted value' do
        response = app.get("/", "HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "Content-Type" => "application/xml")
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response.body).to                    eq("html")
      end

      it 'sets "Content-Type" header according to quality scale value' do
        response = app.get("/", "HTTP_ACCEPT" => "application/json;q=0.6,application/xml;q=0.9,*/*;q=0.8", "Content-Type" => "application/xml")
        expect(response.headers["Content-Type"]).to eq("application/xml; charset=utf-8")
        expect(response.body).to                    eq("xml")
      end
    end

    # See https://github.com/hanami/controller/issues/225
    context "with an accepted format and default response format" do
      let(:app) { Rack::MockRequest.new(MimesWithDefault::Application.new) }
      let(:content_type) { "application/json" }
      let(:response) { app.get("/default_and_accept", "Content-Type" => content_type) }

      it "defaults to the accepted format" do
        expect(response.status).to be(200)
        expect(response.body).to eq('html')
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

      context 'applies the weighting mechanism for media ranges' do
        let(:accept) { "text/*,application/json,text/html,*/*" }

        it "accepts selected mime types" do
          expect(response.headers["X-AcceptDefault"]).to eq("true")
          expect(response.headers["X-AcceptHtml"]).to    eq("true")
          expect(response.headers["X-AcceptXml"]).to     eq("true")
          expect(response.headers["X-AcceptJson"]).to    eq("true")
          expect(response.body).to                       eq("json")
        end
      end
    end
  end
end
