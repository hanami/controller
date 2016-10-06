require 'test_helper'

describe Hanami::Action do
  class FormatController
    class Lookup
      include Hanami::Action

      configure do |config|
        config.handle_exceptions = false
      end

      def call(params)
      end
    end

    class Custom
      include Hanami::Action

      configure do |config|
        config.handle_exceptions = false
      end

      def call(params)
        self.format = params[:format]
      end
    end
    
    class Configuration
      include Hanami::Action

      configuration.default_request_format :jpeg

      def call(params)
        self.body = format
      end
    end
  end

  describe '#format' do
    before do
      @action = FormatController::Lookup.new
    end

    it 'lookup to #content_type if was not explicitly set (default: application/octet-stream)' do
      status, headers, _ = @action.call({})

      @action.format.must_equal   :all
      headers['Content-Type'].must_equal 'application/octet-stream; charset=utf-8'
      status.must_equal                  200
    end

    it "accepts 'text/html' and returns :html" do
      status, headers, _ = @action.call({ 'HTTP_ACCEPT' => 'text/html' })

      @action.format.must_equal    :html
      headers['Content-Type'].must_equal 'text/html; charset=utf-8'
      status.must_equal                   200
    end

    it "accepts unknown mime type and returns :all" do
      status, headers, _ = @action.call({ 'HTTP_ACCEPT' => 'application/unknown' })

      @action.format.must_equal    :all
      headers['Content-Type'].must_equal 'application/octet-stream; charset=utf-8'
      status.must_equal                   200
    end

    # Bug
    # See https://github.com/hanami/controller/issues/104
    it "accepts 'text/html, application/xhtml+xml, image/jxr, */*' and returns :html" do
      status, headers, _ = @action.call({ 'HTTP_ACCEPT' => 'text/html, application/xhtml+xml, image/jxr, */*' })

      @action.format.must_equal    :html
      headers['Content-Type'].must_equal 'text/html; charset=utf-8'
      status.must_equal                   200
    end

    # Bug
    # See https://github.com/hanami/controller/issues/167
    it "accepts '*/*' and returns configured default format" do
      action = FormatController::Configuration.new
      status, headers, _ = action.call({ 'HTTP_ACCEPT' => '*/*' })

      action.format.must_equal    :jpeg
      headers['Content-Type'].must_equal 'image/jpeg; charset=utf-8'
      status.must_equal                   200
    end

    mime_types = ['application/octet-stream', 'text/html']
    Rack::Mime::MIME_TYPES.each do |format, mime_type|
      next if mime_types.include?(mime_type)
      mime_types.push mime_type

      format = format.gsub(/\A\./, '').to_sym

      it "accepts '#{ mime_type }' and returns :#{ format }" do
        status, headers, _ = @action.call({ 'HTTP_ACCEPT' => mime_type })

        @action.format.must_equal   format
        headers['Content-Type'].must_equal "#{mime_type}; charset=utf-8"
        status.must_equal                  200
      end
    end
  end

  describe '#format=' do
    before do
      @action = FormatController::Custom.new
    end

    it "sets :all and returns 'application/octet-stream'" do
      status, headers, _ = @action.call({ format: 'all' })

      @action.format.must_equal   :all
      headers['Content-Type'].must_equal 'application/octet-stream; charset=utf-8'
      status.must_equal                  200
    end

    it "sets nil and raises an error" do
      -> { @action.call({ format: nil }) }.must_raise TypeError
    end

    it "sets '' and raises an error" do
      -> { @action.call({ format: '' }) }.must_raise TypeError
    end

    it "sets an unknown format and raises an error" do
      begin
        @action.call({ format: :unknown })
      rescue => e
        e.must_be_kind_of(Hanami::Controller::UnknownFormatError)
        e.message.must_equal "Cannot find a corresponding Mime type for 'unknown'. Please configure it with Hanami::Controller::Configuration#format."
      end
    end

    Rack::Mime::MIME_TYPES.each do |format, mime_type|
      format = format.gsub(/\A\./, '')

      it "sets :#{ format } and returns '#{ mime_type }'" do
        _, headers, _ = @action.call({ format: format })

        @action.format.must_equal   format.to_sym
        headers['Content-Type'].must_equal "#{mime_type}; charset=utf-8"
      end
    end
  end
end
