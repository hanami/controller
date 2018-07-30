RSpec.describe Hanami::Action do
  class FormatController
    class Lookup < Hanami::Action
      def call(*)
      end
    end

    class Custom < Hanami::Action
      def call(req, res)
        input = req.params[:format]
        input = input.to_sym unless input.nil?

        res.format = format(input)
      end
    end

    class Configuration < Hanami::Action
      def call(*, res)
        res.body = res.format
      end
    end
  end

  describe '#format' do
    let(:action) { FormatController::Lookup.new(configuration: configuration) }

    it 'lookup to #content_type if was not explicitly set (default: application/octet-stream)' do
      response = action.call({})

      expect(response.format).to                  eq(:all)
      expect(response.headers['Content-Type']).to eq('application/octet-stream; charset=utf-8')
      expect(response.status).to                  be(200)
    end

    it "accepts 'text/html' and returns :html" do
      response = action.call('HTTP_ACCEPT' => 'text/html')

      expect(response.format).to                  eq(:html)
      expect(response.headers['Content-Type']).to eq('text/html; charset=utf-8')
      expect(response.status).to                  be(200)
    end

    it "rejects unknown mime type" do
      response = action.call('HTTP_ACCEPT' => 'application/unknown')
      expect(response.status).to                  be(406)
    end

    # Bug
    # See https://github.com/hanami/controller/issues/104
    it "accepts 'text/html, application/xhtml+xml, image/jxr, */*' and returns :html" do
      response = action.call('HTTP_ACCEPT' => 'text/html, application/xhtml+xml, image/jxr, */*')

      expect(response.format).to                  eq(:html)
      expect(response.headers['Content-Type']).to eq('text/html; charset=utf-8')
      expect(response.status).to                  be(200)
    end

    # Bug
    # See https://github.com/hanami/controller/issues/167
    it "accepts '*/*' and returns configured default format" do
      configuration = Hanami::Controller::Configuration.new do |config|
        config.default_response_format = :jpg
      end

      action = FormatController::Configuration.new(configuration: configuration)
      response = action.call('HTTP_ACCEPT' => '*/*')

      expect(response.format).to                  eq(:jpg)
      expect(response.headers['Content-Type']).to eq('image/jpeg; charset=utf-8')
      expect(response.status).to                  be(200)
    end

    Hanami::Action::Mime::TYPES.each do |format, mime_type|
      it "accepts '#{mime_type}' and returns :#{format}" do
        response = action.call('HTTP_ACCEPT' => mime_type)

        expect(response.format).to                  eq(format)
        expect(response.headers['Content-Type']).to eq("#{mime_type}; charset=utf-8")
        expect(response.status).to                  be(200)
      end
    end
  end

  describe '#format=' do
    let(:action) { FormatController::Custom.new(configuration: configuration) }

    it "sets :all and returns 'application/octet-stream'" do
      response = action.call(format: 'all')

      expect(response.format).to                  eq(:all)
      expect(response.headers['Content-Type']).to eq('application/octet-stream; charset=utf-8')
      expect(response.status).to                  be(200)
    end

    it "sets nil and raises an error" do
      expect { action.call(format: nil) }.to raise_error(Hanami::Controller::UnknownFormatError, "Cannot find a corresponding Mime type for ''. Please configure it with Hanami::Controller::Configuration#format.")
    end

    it "sets '' and raises an error" do
      expect { action.call(format: '') }.to raise_error(Hanami::Controller::UnknownFormatError, "Cannot find a corresponding Mime type for ''. Please configure it with Hanami::Controller::Configuration#format.")
    end

    it "sets an unknown format and raises an error" do
      begin
        action.call(format: :unknown)
      rescue => exception
        expect(exception).to         be_kind_of(Hanami::Controller::UnknownFormatError)
        expect(exception.message).to eq("Cannot find a corresponding Mime type for 'unknown'. Please configure it with Hanami::Controller::Configuration#format.")
      end
    end

    Hanami::Action::Mime::TYPES.each do |format, mime_type|
      it "sets #{format} and returns '#{mime_type}'" do
        response = action.call(format: format)

        expect(response.format).to                  eq(format)
        expect(response.headers['Content-Type']).to eq("#{mime_type}; charset=utf-8")
      end
    end
  end
end
