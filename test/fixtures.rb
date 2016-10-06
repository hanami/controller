require 'digest/md5'
require 'hanami/router'
require 'hanami/utils/escape'
require 'hanami/action/params'
require 'hanami/action/cookies'
require 'hanami/action/session'
require 'hanami/action/cache'
require 'hanami/action/glue'

HTTP_TEST_STATUSES_WITHOUT_BODY = Set.new((100..199).to_a << 204 << 205 << 304).freeze
HTTP_TEST_STATUSES = {
  100 => 'Continue',
  101 => 'Switching Protocols',
  102 => 'Processing',
  103 => 'Checkpoint',
  122 => 'Request-URI too long',
  200 => 'OK',
  201 => 'Created',
  202 => 'Accepted',
  203 => 'Non-Authoritative Information',
  204 => 'No Content',
  205 => 'Reset Content',
  206 => 'Partial Content',
  207 => 'Multi-Status',
  208 => 'Already Reported',
  226 => 'IM Used',
  300 => 'Multiple Choices',
  301 => 'Moved Permanently',
  302 => 'Found',
  303 => 'See Other',
  304 => 'Not Modified',
  305 => 'Use Proxy',
  307 => 'Temporary Redirect',
  308 => 'Permanent Redirect',
  400 => 'Bad Request',
  401 => 'Unauthorized',
  402 => 'Payment Required',
  403 => 'Forbidden',
  404 => 'Not Found',
  405 => 'Method Not Allowed',
  406 => 'Not Acceptable',
  407 => 'Proxy Authentication Required',
  408 => 'Request Timeout',
  409 => 'Conflict',
  410 => 'Gone',
  411 => 'Length Required',
  412 => 'Precondition Failed',
  413 => 'Payload Too Large',
  414 => 'URI Too Long',
  415 => 'Unsupported Media Type',
  416 => 'Range Not Satisfiable',
  417 => 'Expectation Failed',
  418 => 'I\'m a teapot',
  420 => 'Enhance Your Calm',
  422 => 'Unprocessable Entity',
  423 => 'Locked',
  424 => 'Failed Dependency',
  426 => 'Upgrade Required',
  428 => 'Precondition Required',
  429 => 'Too Many Requests',
  431 => 'Request Header Fields Too Large',
  444 => 'No Response',
  449 => 'Retry With',
  450 => 'Blocked by Windows Parental Controls',
  451 => 'Wrong Exchange server',
  499 => 'Client Closed Request',
  500 => 'Internal Server Error',
  501 => 'Not Implemented',
  502 => 'Bad Gateway',
  503 => 'Service Unavailable',
  504 => 'Gateway Timeout',
  505 => 'HTTP Version Not Supported',
  506 => 'Variant Also Negotiates',
  507 => 'Insufficient Storage',
  508 => 'Loop Detected',
  510 => 'Not Extended',
  511 => 'Network Authentication Required',
  598 => 'Network read timeout error',
  599 => 'Network connect timeout error'
}

class RecordNotFound < StandardError
end

module Test
  include Hanami::Controller

  class Index
    include Hanami::Action
    expose :xyz

    def call(params)
      @xyz = params[:name]
    end
  end

  class CallAction
    include Hanami::Action

    def call(params)
      self.status  = 201
      self.body    = 'Hi from TestAction!'
      self.headers.merge!({ 'X-Custom' => 'OK' })
    end
  end

  class HandleExceptions
    include Hanami::Action

    configure do |config|
      config.handle_exceptions = false
      config.handle_exception StandardError => 500
    end

    def call(params)
    end
  end
end

module ConfigurationTest
  include Hanami::Controller

  configure do |config|
    config.default_charset = 'utf-8'
  end

  module ConfigurationAction
    include Hanami::Action
  end
end

class ErrorCallAction
  include Hanami::Action

  def call(params)
    raise
  end
end

class MyCustomError < StandardError ; end
class ErrorCallFromInheritedErrorClass
  include Hanami::Action

  handle_exception StandardError => :handler

  def call(params)
    raise MyCustomError
  end

  private

  def handler(exception)
    status 501, 'An inherited exception occurred!'
  end
end

class ErrorCallFromInheritedErrorClassStack
  include Hanami::Action

  handle_exception StandardError => :standard_handler
  handle_exception MyCustomError => :handler

  def call(params)
    raise MyCustomError
  end

  private
  def handler(exception)
    status 501, 'MyCustomError was thrown'
  end

  def standard_handler(exception)
    status 501, 'An unknown error was thrown'
  end
end

class ErrorCallWithSymbolMethodNameAsHandlerAction
  include Hanami::Action

  handle_exception StandardError => :handler

  def call(params)
    raise StandardError
  end

  private
  def handler(exception)
    status 501, 'Please go away!'
  end
end

class ErrorCallWithStringMethodNameAsHandlerAction
  include Hanami::Action

  handle_exception StandardError => 'standard_error_handler'

  def call(params)
    raise StandardError
  end

  private
  def standard_error_handler(exception)
    status 502, exception.message
  end
end

class ErrorCallWithUnsetStatusResponse
  include Hanami::Action

  handle_exception ArgumentError => 'arg_error_handler'

  def call(params)
    raise ArgumentError
  end

  private
  def arg_error_handler(exception)
  end
end

class ErrorCallWithSpecifiedStatusCodeAction
  include Hanami::Action

  handle_exception StandardError => 422

  def call(params)
    raise StandardError
  end
end

class ExposeAction
  include Hanami::Action

  expose :film, :time

  def call(params)
    @film = '400 ASA'
  end
end

class ExposeReservedWordAction
  include Hanami::Action
  include Hanami::Action::Session

  def self.expose_reserved_word(using_internal_method: false)
    if using_internal_method
      _expose :flash
    else
      expose :flash
    end
  end
end

class ZMiddleware
  def initialize(app, &message)
    @app = app
    @message = message
  end

  def call(env)
    code, headers, body = @app.call(env)
    [code, headers.merge!('Z-Middleware' => @message.call), body]
  end
end

class YMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    code, headers, body = @app.call(env)
    [code, headers.merge!('Y-Middleware' => 'OK'), body]
  end
end

class XMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    code, headers, body = @app.call(env)
    [code, headers.merge!('X-Middleware' => 'OK'), body]
  end
end

module UseAction
  class Index
    include Hanami::Action
    use XMiddleware

    def call(params)
      self.body = 'Hello from UseAction::Index'
    end
  end

  class Show
    include Hanami::Action
    use YMiddleware

    def call(params)
      self.body = 'Hello from UseAction::Show'
    end
  end

  class Edit
    include Hanami::Action
    use ZMiddleware do
      'OK'
    end

    def call(params)
      self.body = 'Hello from UseAction::Edit'
    end
  end
end

module NoUseAction
  class Index
    include Hanami::Action

    def call(params)
      self.body = 'Hello from NoUseAction::Index'
    end
  end
end

class BeforeMethodAction
  include Hanami::Action

  expose :article, :logger
  before :set_article, :reverse_article
  append_before :add_first_name_to_logger, :add_last_name_to_logger
  prepend_before :add_title_to_logger

  def initialize(*)
    super
    @logger = []
  end

  def call(params)
  end

  private
  def set_article
    @article = 'Bonjour!'
  end

  def reverse_article
    @article.reverse!
  end

  def add_first_name_to_logger
    @logger << 'John'
  end

  def add_last_name_to_logger
    @logger << 'Doe'
  end

  def add_title_to_logger
    @logger << 'Mr.'
  end
end

class SubclassBeforeMethodAction < BeforeMethodAction
  before :upcase_article

  private
  def upcase_article
    @article.upcase!
  end
end

class ParamsBeforeMethodAction < BeforeMethodAction
  expose :exposed_params

  private
  def upcase_article
  end

  def set_article(params)
    @exposed_params = params
    @article = super() + params[:bang]
  end
end

class ErrorBeforeMethodAction < BeforeMethodAction
  private

  def set_article
    raise
  end
end

class HandledErrorBeforeMethodAction < BeforeMethodAction
  configure do |config|
    config.handle_exceptions = true
    config.handle_exception RecordNotFound => 404
  end

  private

  def set_article
    raise RecordNotFound.new
  end
end

class BeforeBlockAction
  include Hanami::Action

  expose :article
  before { @article = 'Good morning!' }
  before { @article.reverse! }

  def call(params)
  end
end

class YieldBeforeBlockAction < BeforeBlockAction
  expose :yielded_params
  before {|params| @yielded_params = params }
end

class AfterMethodAction
  include Hanami::Action

  expose :egg, :logger
  after  :set_egg, :scramble_egg
  append_after :add_first_name_to_logger, :add_last_name_to_logger
  prepend_after :add_title_to_logger

  def initialize(*)
    super
    @logger = []
  end

  def call(params)
  end

  private
  def set_egg
    @egg = 'Egg!'
  end

  def scramble_egg
    @egg = 'gE!g'
  end

  def add_first_name_to_logger
    @logger << 'Jane'
  end

  def add_last_name_to_logger
    @logger << 'Dixit'
  end

  def add_title_to_logger
    @logger << 'Mrs.'
  end
end

class SubclassAfterMethodAction < AfterMethodAction
  after :upcase_egg

  private
  def upcase_egg
    @egg.upcase!
  end
end

class ParamsAfterMethodAction < AfterMethodAction
  private
  def scramble_egg(params)
    @egg = super() + params[:question]
  end
end

class ErrorAfterMethodAction < AfterMethodAction
  private
  def set_egg
    raise
  end
end

class HandledErrorAfterMethodAction < AfterMethodAction
  configure do |config|
    config.handle_exceptions = true
    config.handle_exception RecordNotFound => 404
  end

  private

  def set_egg
    raise RecordNotFound.new
  end
end

class AfterBlockAction
  include Hanami::Action

  expose :egg
  after { @egg = 'Coque' }
  after { @egg.reverse! }

  def call(params)
  end
end

class YieldAfterBlockAction < AfterBlockAction
  expose :meaning_of_life_params
  before {|params| @meaning_of_life_params = params }
end

class SessionAction
  include Hanami::Action
  include Hanami::Action::Session

  def call(params)
  end
end

class RedirectAction
  include Hanami::Action

  def call(params)
    redirect_to '/destination'
  end
end

class StatusRedirectAction
  include Hanami::Action

  def call(params)
    redirect_to '/destination', status: 301
  end
end

class SafeStringRedirectAction
  include Hanami::Action

  def call(params)
    location = Hanami::Utils::Escape::SafeString.new('/destination')
    redirect_to location
  end
end

class GetCookiesAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    self.body = cookies[:foo]
  end
end

class ChangeCookiesAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    self.body = cookies[:foo]
    cookies[:foo] = 'baz'
  end
end

class GetDefaultCookiesAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    self.body = ''
    cookies[:bar] = 'foo'
  end
end

class GetOverwrittenCookiesAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    self.body = ''
    cookies[:bar] = { value: 'foo', domain: 'hanamirb.com', path: '/action', secure: false, httponly: false }
  end
end

class GetAutomaticallyExpiresCookiesAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    cookies[:bar] = { value: 'foo', max_age: 120 }
  end
end

class SetCookiesAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    self.body = 'yo'
    cookies[:foo] = 'yum!'
  end
end

class SetCookiesWithOptionsAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def initialize(expires: Time.now.utc)
    @expires = expires
  end

  def call(params)
    cookies[:kukki] = { value: 'yum!', domain: 'hanamirb.org', path: '/controller', expires: @expires, secure: true, httponly: true }
  end
end

class RemoveCookiesAction
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    cookies[:rm] = nil
  end
end

class ThrowCodeAction
  include Hanami::Action

  def call(params)
    halt params[:status].to_i, params[:message]
  end
end

class CatchAndThrowSymbolAction
  include Hanami::Action

  def call(params)
    catch :done do
      throw :done, 1
      raise "This code shouldn't be reachable"
    end
  end
end

class ThrowBeforeMethodAction
  include Hanami::Action

  before :authorize!
  before :set_body

  def call(params)
    self.body = 'Hello!'
  end

  private
  def authorize!
    halt 401
  end

  def set_body
    self.body = 'Hi!'
  end
end

class ThrowBeforeBlockAction
  include Hanami::Action

  before { halt 401 }
  before { self.body = 'Hi!' }

  def call(params)
    self.body = 'Hello!'
  end
end

class ThrowAfterMethodAction
  include Hanami::Action

  after :raise_timeout!
  after :set_body

  def call(params)
    self.body = 'Hello!'
  end

  private
  def raise_timeout!
    halt 408
  end

  def set_body
    self.body = 'Later!'
  end
end

class ThrowAfterBlockAction
  include Hanami::Action

  after { halt 408 }
  after { self.body = 'Later!' }

  def call(params)
    self.body = 'Hello!'
  end
end

class HandledExceptionAction
  include Hanami::Action
  handle_exception RecordNotFound => 404

  def call(params)
    raise RecordNotFound.new
  end
end

class DomainLogicException < StandardError
end

module Exceptions
  include Hanami::Controller

  configure do |config|
    config.handle_exception DomainLogicException => 400
  end

  class GlobalHandledExceptionAction
    include Hanami::Action

    def call(params)
      raise DomainLogicException.new
    end
  end
end

class UnhandledExceptionAction
  include Hanami::Action

  def call(params)
    raise RecordNotFound.new
  end
end

class ParamsAction
  include Hanami::Action

  def call(params)
    self.body = params.to_h.inspect
  end
end

class WhitelistedParamsAction
  class Params < Hanami::Action::Params
    params do
      required(:id).maybe
      required(:article).schema do
        required(:tags).each(:str?)
      end
    end
  end

  include Hanami::Action
  params Params

  def call(params)
    self.body = params.to_h.inspect
  end
end

class WhitelistedDslAction
  include Hanami::Action

  params do
    required(:username).filled
  end

  def call(params)
    self.body = params.to_h.inspect
  end
end

class WhitelistedUploadDslAction
  include Hanami::Action

  params do
    required(:id).maybe
    required(:upload).filled
  end

  def call(params)
    self.body = params.to_h.inspect
  end
end

class ParamsValidationAction
  include Hanami::Action

  params do
    required(:email).filled(:str?)
  end

  def call(params)
    halt 400 unless params.valid?
  end
end

class TestParams < Hanami::Action::Params
  params do
    required(:email).filled(format?: /\A.+@.+\z/)
    required(:name).filled
    required(:tos).filled(:bool?)
    required(:age).filled(:int?)
    required(:address).schema do
      required(:line_one).filled
      required(:deep).schema do
        required(:deep_attr).filled(:str?)
      end
    end
  end
end

class NestedParams < Hanami::Action::Params
  params do
    required(:signup).schema do
      required(:name).filled(:str?)
      required(:age).filled(:int?, gteq?: 18)
    end
  end
end

class Root
  include Hanami::Action

  def call(params)
    self.body = params.to_h.inspect
    headers.merge!({'X-Test' => 'test'})
  end
end

module About
  class Team < Root
  end

  class Contacts
    include Hanami::Action

    def call(params)
      self.body = params.to_h.inspect
    end
  end
end

module Identity
  class Action
    include Hanami::Action

    def call(params)
      self.body = params.to_h.inspect
    end
  end

  Show    = Class.new(Action)
  New     = Class.new(Action)
  Create  = Class.new(Action)
  Edit    = Class.new(Action)
  Update  = Class.new(Action)
  Destroy = Class.new(Action)
end

module Flowers
  class Action
    include Hanami::Action

    def call(params)
      self.body = params.to_h.inspect
    end
  end

  Index   = Class.new(Action)
  Show    = Class.new(Action)
  New     = Class.new(Action)
  Create  = Class.new(Action)
  Edit    = Class.new(Action)
  Update  = Class.new(Action)
  Destroy = Class.new(Action)
end

module Painters
  class Update
    include Hanami::Action

    params do
      required(:painter).schema do
        required(:first_name).filled(:str?)
        required(:last_name).filled(:str?)
      end
    end

    def call(params)
      self.body = params.to_h.inspect
    end
  end
end

module Dashboard
  class Index
    include Hanami::Action
    include Hanami::Action::Session
    before :authenticate!

    def call(params)
    end

    private
    def authenticate!
      halt 401 unless loggedin?
    end

    def loggedin?
      session.has_key?(:user_id)
    end
  end
end

module Sessions
  class Create
    include Hanami::Action
    include Hanami::Action::Session

    def call(params)
      session[:user_id] = 23
      redirect_to '/'
    end
  end

  class Destroy
    include Hanami::Action
    include Hanami::Action::Session

    def call(params)
      session[:user_id] = nil
    end
  end
end

class StandaloneSession
  include Hanami::Action
  include Hanami::Action::Session

  def call(params)
    session[:age] = Time.now.year - 1982
  end
end

module Glued
  class SendFile
    include Hanami::Action
    include Hanami::Action::Glue

    def call(params)
      self.body = ::Rack::File.new(nil)
    end
  end
end

class ArtistNotFound < StandardError
end

module App
  class CustomError < StandardError
  end

  class StandaloneAction
    include Hanami::Action
    handle_exception App::CustomError => 400

    def call(params)
      raise App::CustomError
    end
  end
end

module App2
  class CustomError < StandardError
  end

  module Standalone
    class Index
      include Hanami::Action
      handle_exception App2::CustomError => 400

      def call(params)
        raise App2::CustomError
      end
    end
  end
end

module MusicPlayer
  module Controllers
    include Hanami::Controller

    configure do |config|
      config.handle_exception ArgumentError => 400
      # config.action_module    MusicPlayer::Action
      config.default_headers(
        'X-Frame-Options' => 'DENY'
      )

      config.prepare do
        include Hanami::Action::Cookies
        include Hanami::Action::Session
        include MusicPlayer::Controllers::Authentication
      end
    end

    module Authentication
      def self.included(action)
        action.class_eval { expose :current_user }
      end

      private
      def current_user
        'Luca'
      end
    end

    class Dashboard
      class Index
        include Hanami::Action

        def call(params)
          self.body = 'Muzic!'
          headers['X-Frame-Options'] = 'ALLOW FROM https://example.org'
        end
      end

      class Show
        include Hanami::Action

        def call(params)
          raise ArgumentError
        end
      end
    end

    module Artists
      class Index
        include Hanami::Action

        def call(params)
          self.body = current_user
        end
      end

      class Show
        include Hanami::Action

        handle_exception ArtistNotFound => 404

        def call(params)
          raise ArtistNotFound
        end
      end
    end
  end
end

class VisibilityAction
  include Hanami::Action
  include Hanami::Action::Cookies
  include Hanami::Action::Session

  configure do |config|
    config.handle_exceptions = false
  end

  def call(params)
    self.body   = 'x'
    self.status = 201
    self.format = :json

    self.headers.merge!('X-Custom' => 'OK')
    headers.merge!('Y-Custom'      => 'YO')

    self.session[:foo] = 'bar'

    # PRIVATE
    # self.configuration
    # self.finish

    # PROTECTED
    self.response
    self.cookies
    self.session

    response
    cookies
    session
  end
end

module SendFileTest
  include Hanami::Controller
  configure do |config|
    config.handle_exceptions = false
  end

  module Files
    class Show
      include Hanami::Action

      def call(params)
        id = params[:id]
        # This if statement is only for testing purpose
        if id == "1"
          send_file Pathname.new('test/assets/test.txt')
        elsif id == "2"
          send_file Pathname.new('test/assets/hanami.png')
        else
          send_file Pathname.new('test/assets/unknown.txt')
        end
      end
    end

    class Flow
      include Hanami::Action

      def call(params)
        send_file Pathname.new('test/assets/test.txt')
        redirect_to '/'
      end
    end
  end
end

module HeadTest
  include Hanami::Controller

  configure do |config|
    config.handle_exceptions = false
    config.default_headers(
      'X-Frame-Options' => 'DENY'
    )

    config.prepare do
      include Hanami::Action::Glue
      include Hanami::Action::Session
    end
  end

  module Home
    class Index
      include Hanami::Action

      def call(params)
        self.body = 'index'
      end
    end

    class Code
      include Hanami::Action
      include Hanami::Action::Cache

      def call(params)
        content = 'code'

        headers.merge!(
          'Allow'            => 'GET, HEAD',
          'Content-Encoding' => 'identity',
          'Content-Language' => 'en',
          'Content-Length'   => content.length,
          'Content-Location' => 'relativeURI',
          'Content-MD5'      => Digest::MD5.hexdigest(content),
          'Expires'          => 'Thu, 01 Dec 1994 16:00:00 GMT',
          'Last-Modified'    => 'Wed, 21 Jan 2015 11:32:10 GMT'
        )

        self.status = params[:code].to_i
        self.body   = 'code'
      end
    end

    class Override
      include Hanami::Action

      def call(params)
        self.headers.merge!(
          'Last-Modified' => 'Fri, 27 Nov 2015 13:32:36 GMT',
          'X-Rate-Limit'  => '4000',
          'X-No-Pass'     => 'true'
        )

        self.status = 204
      end

      private

      def keep_response_header?(header)
        super || 'X-Rate-Limit' == header
      end
    end
  end
end

module FullStack
  include Hanami::Controller
  configure do |config|
    config.handle_exceptions = false

    config.prepare do
      include Hanami::Action::Glue
      include Hanami::Action::Session
    end
  end

  module Controllers
    module Home
      class Index
        include Hanami::Action
        expose :greeting

        def call(params)
          @greeting = 'Hello'
        end
      end

      class Head
        include Hanami::Action

        def call(params)
          headers['X-Renderable'] = renderable?.to_s
          self.body = 'foo'
        end
      end
    end

    module Books
      class Index
        include Hanami::Action

        def call(params)
        end
      end

      class Create
        include Hanami::Action

        params do
          required(:title).filled(:str?)
        end

        def call(params)
          params.valid?

          redirect_to '/books'
        end
      end

      class Update
        include Hanami::Action

        params do
          required(:id).value(:int?)
          required(:book).schema do
            required(:title).filled(:str?)
            required(:author).schema do
              required(:name).filled(:str?)
              required(:favourite_colour)
            end
          end
        end

        def call(params)
          valid = params.valid?

          self.status = 201
          self.body = Marshal.dump({
            symbol_access: params[:book][:author] && params[:book][:author][:name],
            valid: valid,
            errors: params.errors.to_h
          })
        end
      end
    end

    module Poll
      class Start
        include Hanami::Action

        def call(params)
          redirect_to '/poll/1'
        end
      end

      class Step1
        include Hanami::Action

        def call(params)
          if @_env['REQUEST_METHOD'] == 'GET'
            flash[:notice] = "Start the poll"
          else
            flash[:notice] = "Step 1 completed"
            redirect_to '/poll/2'
          end
        end
      end

      class Step2
        include Hanami::Action

        def call(params)
          if @_env['REQUEST_METHOD'] == 'POST'
            flash[:notice] = "Poll completed"
            redirect_to '/'
          end
        end
      end
    end

    module Users
      class Show
        include Hanami::Action

        before :redirect_to_root
        after :set_body

        def call(params)
          self.body = "call method shouldn't be called"
        end

        private

        def redirect_to_root
          redirect_to '/'
        end

        def set_body
          self.body = "after callback shouldn't be called"
        end
      end
    end
  end

  class Renderer
    def render(env, response)
      action = env.delete('hanami.action')

      if response[0] == 200 && action.renderable?
        response[2] = "#{ action.class.name } #{ action.exposures } params: #{ action.params.to_h }"
      end

      response
    end
  end

  class Application
    def initialize
      resolver = Hanami::Routing::EndpointResolver.new(namespace: FullStack::Controllers)
      routes   = Hanami::Router.new(resolver: resolver) do
        get '/',     to: 'home#index'
        get '/head', to: 'home#head'
        resources :books, only: [:index, :create, :update]

        get '/poll', to: 'poll#start'

        namespace 'poll' do
          get  '/1', to: 'poll#step1'
          post '/1', to: 'poll#step1'
          get  '/2', to: 'poll#step2'
          post '/2', to: 'poll#step2'
        end

        namespace 'users' do
          get '/1', to: 'users#show'
        end
      end

      @renderer   = Renderer.new
      @middleware = Rack::Builder.new do
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end
    end

    def call(env)
      @renderer.render(env, @middleware.call(env))
    end
  end
end

class MethodInspectionAction
  include Hanami::Action

  def call(params)
    self.body = request_method
  end
end

class RackExceptionAction
  include Hanami::Action

  class TestException < ::StandardError
  end

  def call(params)
    raise TestException.new
  end
end

class HandledRackExceptionAction
  include Hanami::Action

  class TestException < ::StandardError
  end

  handle_exception TestException => 500

  def call(params)
    raise TestException.new
  end
end

module SessionWithCookies
  include Hanami::Controller
  configure do |config|
    config.handle_exceptions = false

    config.prepare do
      include Hanami::Action::Glue
      include Hanami::Action::Session
      include Hanami::Action::Cookies
    end
  end

  module Controllers
    module Home
      class Index
        include Hanami::Action

        def call(params)
        end
      end
    end
  end

  class Renderer
    def render(env, response)
      action = env.delete('hanami.action')

      if response[0] == 200 && action.renderable?
        response[2] = "#{ action.class.name } #{ action.exposures }"
      end

      response
    end
  end

  class Application
    def initialize
      resolver = Hanami::Routing::EndpointResolver.new(namespace: SessionWithCookies::Controllers)
      routes   = Hanami::Router.new(resolver: resolver) do
        get '/',     to: 'home#index'
      end

      @renderer   = Renderer.new
      @middleware = Rack::Builder.new do
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end
    end

    def call(env)
      @renderer.render(env, @middleware.call(env))
    end
  end
end

module SessionsWithoutCookies
  include Hanami::Controller

  configure do |config|
    config.handle_exceptions = false

    config.prepare do
      include Hanami::Action::Glue
      include Hanami::Action::Session
    end
  end

  module Controllers
    module Home
      class Index
        include Hanami::Action

        def call(params)
        end
      end
    end
  end

  class Renderer
    def render(env, response)
      action = env.delete('hanami.action')

      if response[0] == 200 && action.renderable?
        response[2] = "#{ action.class.name } #{ action.exposures }"
      end

      response
    end
  end

  class Application
    def initialize
      resolver = Hanami::Routing::EndpointResolver.new(namespace: SessionsWithoutCookies::Controllers)
      routes   = Hanami::Router.new(resolver: resolver) do
        get '/',     to: 'home#index'
      end

      @renderer   = Renderer.new
      @middleware = Rack::Builder.new do
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end
    end

    def call(env)
      @renderer.render(env, @middleware.call(env))
    end
  end
end
