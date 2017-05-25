RSpec.describe Hanami::Action do
  class FormatController
    class Lookup
      include Hanami::Action
      configuration.handle_exceptions = false

      def call(params)
      end
    end

    class Custom
      include Hanami::Action
      configuration.handle_exceptions = false

      def call(params)
        self.format = params[:format]
      end
    end

    class Configuration
      include Hanami::Action

      configuration.default_request_format :jpg

      def call(_params)
        self.body = format
      end
    end
  end

  describe '#format' do
    let(:action) { FormatController::Lookup.new }

    it 'lookup to #content_type if was not explicitly set (default: application/octet-stream)' do
      status, headers, = action.call({})

      expect(action.format).to           eq(:all)
      expect(headers['Content-Type']).to eq('application/octet-stream; charset=utf-8')
      expect(status).to                  be(200)
    end

    it "accepts 'text/html' and returns :html" do
      status, headers, = action.call('HTTP_ACCEPT' => 'text/html')

      expect(action.format).to           eq(:html)
      expect(headers['Content-Type']).to eq('text/html; charset=utf-8')
      expect(status).to                  be(200)
    end

    it "accepts unknown mime type and returns :all" do
      status, headers, = action.call('HTTP_ACCEPT' => 'application/unknown')

      expect(action.format).to           eq(:all)
      expect(headers['Content-Type']).to eq('application/octet-stream; charset=utf-8')
      expect(status).to                  be(200)
    end

    # Bug
    # See https://github.com/hanami/controller/issues/104
    it "accepts 'text/html, application/xhtml+xml, image/jxr, */*' and returns :html" do
      status, headers, = action.call('HTTP_ACCEPT' => 'text/html, application/xhtml+xml, image/jxr, */*')

      expect(action.format).to           eq(:html)
      expect(headers['Content-Type']).to eq('text/html; charset=utf-8')
      expect(status).to                  be(200)
    end

    # Bug
    # See https://github.com/hanami/controller/issues/167
    it "accepts '*/*' and returns configured default format" do
      action = FormatController::Configuration.new
      status, headers, = action.call('HTTP_ACCEPT' => '*/*')

      expect(action.format).to           eq(:jpg)
      expect(headers['Content-Type']).to eq('image/jpeg; charset=utf-8')
      expect(status).to                  be(200)
    end

    Hanami::Action::Mime::MIME_TYPES.each do |format, mime_type|
      it "accepts '#{mime_type}' and returns :#{format}" do
        status, headers, = action.call('HTTP_ACCEPT' => mime_type)

        expect(action.format).to           eq(format)
        expect(headers['Content-Type']).to eq("#{mime_type}; charset=utf-8")
        expect(status).to                  be(200)
      end
    end
  end

  describe '#format=' do
    let(:action) { FormatController::Custom.new }

    it "sets :all and returns 'application/octet-stream'" do
      status, headers, = action.call(format: 'all')

      expect(action.format).to           eq(:all)
      expect(headers['Content-Type']).to eq('application/octet-stream; charset=utf-8')
      expect(status).to                  be(200)
    end

    it "sets nil and raises an error" do
      expect { action.call(format: nil) }.to raise_error(TypeError)
    end

    it "sets '' and raises an error" do
      expect { action.call(format: '') }.to raise_error(TypeError)
    end

    it "sets an unknown format and raises an error" do
      begin
        action.call(format: :unknown)
      rescue => exception
        expect(exception).to         be_kind_of(Hanami::Controller::UnknownFormatError)
        expect(exception.message).to eq("Cannot find a corresponding Mime type for 'unknown'. Please configure it with Hanami::Controller::Configuration#format.")
      end
    end

    Hanami::Action::Mime::MIME_TYPES.each do |format, mime_type|
      it "sets #{format} and returns '#{mime_type}'" do
        _, headers, = action.call(format: format)

        expect(action.format).to           eq(format)
        expect(headers['Content-Type']).to eq("#{mime_type}; charset=utf-8")
      end
    end
  end
end
