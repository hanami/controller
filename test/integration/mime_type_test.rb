require 'test_helper'
require 'lotus/router'

MimeRoutes = Lotus::Router.new do
  get '/',           to: 'mimes#default'
  get '/custom',     to: 'mimes#custom'
  get '/accept',     to: 'mimes#accept'
  get '/restricted', to: 'mimes#restricted'
end

class MimesController
  include Lotus::Controller

  action 'Default' do
    def call(params)
    end
  end

  action 'Custom' do
    def call(params)
      self.format = :xml
    end
  end

  action 'Accept' do
    def call(params)
      self.headers.merge!({'X-AcceptDefault' => accept?('application/octet-stream').to_s })
      self.headers.merge!({'X-AcceptHtml'    => accept?('text/html').to_s })
      self.headers.merge!({'X-AcceptXml'     => accept?('application/xml').to_s })
      self.headers.merge!({'X-AcceptJson'    => accept?('text/json').to_s })
    end
  end

  action 'Restricted' do
    accept :html, :json

    def call(params)
    end
  end
end

describe 'Content type' do
  before do
    @app = Rack::MockRequest.new(MimeRoutes)
  end

  it 'fallbacks to the default "Content-Type" header when the request is lacking of this information' do
    response = @app.get('/')
    response.headers['Content-Type'].must_equal 'application/octet-stream'
  end

  it 'returns the specified "Content-Type" header' do
    response = @app.get('/custom')
    response.headers['Content-Type'].must_equal 'application/xml'
  end

  describe 'when Accept is sent' do
    it 'sets "Content-Type" header according to "Accept"' do
      response = @app.get('/', 'HTTP_ACCEPT' => '*/*')
      response.headers['Content-Type'].must_equal 'application/octet-stream'
    end

    it 'sets "Content-Type" header according to "Accept"' do
      response = @app.get('/', 'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')
      response.headers['Content-Type'].must_equal 'text/html'
    end

    it 'sets "Content-Type" header according to "Accept" quality scale' do
      response = @app.get('/', 'HTTP_ACCEPT' => 'application/json;q=0.6,application/xml;q=0.9,*/*;q=0.8')
      response.headers['Content-Type'].must_equal 'application/xml'
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
      end
    end

    describe 'when "text/html"' do
      let(:accept) { 'text/html' }

      it 'accepts selected mime types' do
        @response.headers['X-AcceptDefault'].must_equal 'false'
        @response.headers['X-AcceptHtml'].must_equal    'true'
        @response.headers['X-AcceptXml'].must_equal     'false'
        @response.headers['X-AcceptJson'].must_equal    'false'
      end
    end

    describe 'when weighted' do
      let(:accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9' }

      it 'accepts selected mime types' do
        @response.headers['X-AcceptDefault'].must_equal 'false'
        @response.headers['X-AcceptHtml'].must_equal    'true'
        @response.headers['X-AcceptXml'].must_equal     'true'
        @response.headers['X-AcceptJson'].must_equal    'false'
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
