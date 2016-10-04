require 'test_helper'
require 'hanami/router'

MimeRoutes = Hanami::Router.new do
  get '/',                   to: 'mimes#default'
  get '/custom',             to: 'mimes#custom'
  get '/configuration',      to: 'mimes#configuration'
  get '/accept',             to: 'mimes#accept'
  get '/restricted',         to: 'mimes#restricted'
  get '/latin',              to: 'mimes#latin'
  get '/nocontent',          to: 'mimes#no_content'
  get '/response',           to: 'mimes#default_response'
  get '/overwritten_format', to: 'mimes#override_default_response'
  get '/custom_from_accept', to: 'mimes#custom_from_accept'
end

module Mimes
  class Default
    include Hanami::Action

    def call(params)
      self.body = format
    end
  end

  class Configuration
    include Hanami::Action

    configuration.default_request_format :html
    configuration.default_charset 'ISO-8859-1'

    def call(params)
      self.body = format
    end
  end

  class Custom
    include Hanami::Action

    def call(params)
      self.format = :xml
      self.body   = format
    end
  end

  class Latin
    include Hanami::Action

    def call(params)
      self.charset = 'latin1'
      self.format  = :html
      self.body    = format
    end
  end

  class Accept
    include Hanami::Action

    def call(params)
      self.headers.merge!({'X-AcceptDefault' => accept?('application/octet-stream').to_s })
      self.headers.merge!({'X-AcceptHtml'    => accept?('text/html').to_s })
      self.headers.merge!({'X-AcceptXml'     => accept?('application/xml').to_s })
      self.headers.merge!({'X-AcceptJson'    => accept?('text/json').to_s })

      self.body = format
    end
  end

  class CustomFromAccept
    include Hanami::Action

    configuration.format custom: 'application/custom'
    accept :json, :custom

    def call(params)
      self.body = format
    end
  end

  class Restricted
    include Hanami::Action

    configuration.format custom: 'application/custom'
    accept :html, :json, :custom

    def call(params)
    end
  end

  class NoContent
    include Hanami::Action

    def call(params)
      self.status = 204
    end
  end

  class DefaultResponse
    include Hanami::Action

    configuration.default_request_format :html
    configuration.default_response_format :json

    def call(params)
      self.body = configuration.default_request_format
    end
  end

  class OverrideDefaultResponse
    include Hanami::Action

    configuration.default_response_format :json

    def call(params)
      self.format = :xml
    end
  end

end

describe 'Content type' do
  before do
    @app = Rack::MockRequest.new(MimeRoutes)
  end

  it 'fallbacks to the default "Content-Type" header when the request is lacking of this information' do
    response = @app.get('/')
    response.headers['Content-Type'].must_equal 'application/octet-stream; charset=utf-8'
    response.body.must_equal                    'all'
  end

  it 'fallbacks to the default format and charset, set in the configuration' do
    response = @app.get('/configuration')
    response.headers['Content-Type'].must_equal 'text/html; charset=ISO-8859-1'
    response.body.must_equal                    'html'
  end

  it 'returns the specified "Content-Type" header' do
    response = @app.get('/custom')
    response.headers['Content-Type'].must_equal 'application/xml; charset=utf-8'
    response.body.must_equal                    'xml'
  end

  it 'returns the custom charser header' do
    response = @app.get('/latin')
    response.headers['Content-Type'].must_equal 'text/html; charset=latin1'
    response.body.must_equal                    'html'
  end

  it 'uses default_response_format if set in the configuration regardless of request format' do
    response = @app.get('/response')
    response.headers['Content-Type'].must_equal 'application/json; charset=utf-8'
    response.body.must_equal                    'html'
  end

  it 'allows to override default_response_format' do
    response = @app.get('/overwritten_format')
    response.headers['Content-Type'].must_equal 'application/xml; charset=utf-8'
  end

  # FIXME Review if this test must be in place
  it 'does not produce a "Content-Type" header when the request has a 204 No Content status'
  # it 'does not produce a "Content-Type" header when the request has a 204 No Content status' do
  #   response = @app.get('/nocontent')
  #   response.headers['Content-Type'].must_be_nil
  #   response.body.must_equal                    ''
  # end

  describe 'when Accept is sent' do
    it 'sets "Content-Type" header according to "Accept"' do
      response = @app.get('/', 'HTTP_ACCEPT' => '*/*')
      response.headers['Content-Type'].must_equal 'application/octet-stream; charset=utf-8'
      response.body.must_equal                    'all'
    end

    it 'sets "Content-Type" header according to "Accept"' do
      response = @app.get('/custom_from_accept', 'HTTP_ACCEPT' => 'application/custom')
      response.headers['Content-Type'].must_equal 'application/custom; charset=utf-8'
      response.body.must_equal                    'custom'
    end

    it 'sets "Content-Type" header according to "Accept"' do
      response = @app.get('/custom_from_accept', 'HTTP_ACCEPT' => 'application/custom;q=0.9, application/json;q=0.5')
      response.headers['Content-Type'].must_equal 'application/custom; charset=utf-8'
      response.body.must_equal                    'custom'
    end

    it 'sets "Content-Type" header according to "Accept"' do
      response = @app.get('/custom_from_accept', 'HTTP_ACCEPT' => 'application/custom;q=0.1, application/json;q=0.5')
      response.headers['Content-Type'].must_equal 'application/json; charset=utf-8'
      response.body.must_equal                    'json'
    end

    it 'sets "Content-Type" header according to "Accept"' do
      response = @app.get('/', 'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')
      response.headers['Content-Type'].must_equal 'text/html; charset=utf-8'
      response.body.must_equal                    'html'
    end

    it 'sets "Content-Type" header according to "Accept" quality scale' do
      response = @app.get('/', 'HTTP_ACCEPT' => 'application/json;q=0.6,application/xml;q=0.9,*/*;q=0.8')
      response.headers['Content-Type'].must_equal 'application/xml; charset=utf-8'
      response.body.must_equal                    'xml'
    end
  end
end

describe 'Accept' do
  before do
    @app      = Rack::MockRequest.new(MimeRoutes)
    @response = @app.get('/accept', 'HTTP_ACCEPT' => accept)
  end

  describe 'when Accept is missing' do
    let(:accept) { nil }

    it 'accepts all' do
      @response.headers['X-AcceptDefault'].must_equal 'true'
      @response.headers['X-AcceptHtml'].must_equal    'true'
      @response.headers['X-AcceptXml'].must_equal     'true'
      @response.headers['X-AcceptJson'].must_equal    'true'
      @response.body.must_equal                       'all'
    end
  end

  describe 'when Accept is sent' do
    describe 'when "*/*"' do
      let(:accept) { '*/*' }

      it 'accepts all' do
        @response.headers['X-AcceptDefault'].must_equal 'true'
        @response.headers['X-AcceptHtml'].must_equal    'true'
        @response.headers['X-AcceptXml'].must_equal     'true'
        @response.headers['X-AcceptJson'].must_equal    'true'
        @response.body.must_equal                       'all'
      end
    end

    describe 'when "text/html"' do
      let(:accept) { 'text/html' }

      it 'accepts selected mime types' do
        @response.headers['X-AcceptDefault'].must_equal 'false'
        @response.headers['X-AcceptHtml'].must_equal    'true'
        @response.headers['X-AcceptXml'].must_equal     'false'
        @response.headers['X-AcceptJson'].must_equal    'false'
        @response.body.must_equal                       'html'
      end
    end

    describe 'when weighted' do
      let(:accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9' }

      it 'accepts selected mime types' do
        @response.headers['X-AcceptDefault'].must_equal 'false'
        @response.headers['X-AcceptHtml'].must_equal    'true'
        @response.headers['X-AcceptXml'].must_equal     'true'
        @response.headers['X-AcceptJson'].must_equal    'false'
        @response.body.must_equal                       'html'
      end
    end
  end
end

describe 'Restricted Accept' do
  before do
    @app      = Rack::MockRequest.new(MimeRoutes)
    @response = @app.get('/restricted', 'HTTP_ACCEPT' => accept)
  end

  describe 'when Accept is missing' do
    let(:accept) { nil }

    it 'returns the mime type according to the application defined policy' do
      @response.status.must_equal 200
    end
  end

  describe 'when Accept is sent' do
    describe 'when "*/*"' do
      let(:accept) { '*/*' }

      it 'returns the mime type according to the application defined policy' do
        @response.status.must_equal 200
      end
    end

    describe 'when accepted' do
      let(:accept) { 'text/html' }

      it 'accepts selected mime types' do
        @response.status.must_equal 200
      end
    end

    describe 'when custom mime type' do
      let(:accept) { 'application/custom' }

      it 'accepts selected mime types' do
        @response.status.must_equal 200
      end
    end

    describe 'when not accepted' do
      let(:accept) { 'application/xml' }

      it 'accepts selected mime types' do
        @response.status.must_equal 406
      end
    end

    describe 'when weighted' do
      let(:accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9' }

      it 'accepts selected mime types' do
        @response.status.must_equal 200
      end
    end
  end
end
