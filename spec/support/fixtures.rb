require "json"
require "digest/md5"
require "hanami/router"
require "hanami/middleware/body_parser"
require "hanami/utils/escape"
require "hanami/action/params"
require "hanami/action/cookies"
require "hanami/action/session"
require "hanami/action/cache"
require "hanami/action/glue"
require_relative "./renderer"

HTTP_TEST_STATUSES_WITHOUT_BODY = Set.new((100..199).to_a << 204 << 205 << 304).freeze
HTTP_TEST_STATUSES = {
  100 => "Continue",
  101 => "Switching Protocols",
  102 => "Processing",
  103 => "Checkpoint",
  122 => "Request-URI too long",
  200 => "OK",
  201 => "Created",
  202 => "Accepted",
  203 => "Non-Authoritative Information",
  204 => "No Content",
  205 => "Reset Content",
  206 => "Partial Content",
  207 => "Multi-Status",
  208 => "Already Reported",
  226 => "IM Used",
  300 => "Multiple Choices",
  301 => "Moved Permanently",
  302 => "Found",
  303 => "See Other",
  304 => "Not Modified",
  305 => "Use Proxy",
  307 => "Temporary Redirect",
  308 => "Permanent Redirect",
  400 => "Bad Request",
  401 => "Unauthorized",
  402 => "Payment Required",
  403 => "Forbidden",
  404 => "Not Found",
  405 => "Method Not Allowed",
  406 => "Not Acceptable",
  407 => "Proxy Authentication Required",
  408 => "Request Timeout",
  409 => "Conflict",
  410 => "Gone",
  411 => "Length Required",
  412 => "Precondition Failed",
  413 => "Payload Too Large",
  414 => "URI Too Long",
  415 => "Unsupported Media Type",
  416 => "Range Not Satisfiable",
  417 => "Expectation Failed",
  418 => "I'm a teapot",
  420 => "Enhance Your Calm",
  422 => "Unprocessable Entity",
  423 => "Locked",
  424 => "Failed Dependency",
  426 => "Upgrade Required",
  428 => "Precondition Required",
  429 => "Too Many Requests",
  431 => "Request Header Fields Too Large",
  444 => "No Response",
  449 => "Retry With",
  450 => "Blocked by Windows Parental Controls",
  451 => "Wrong Exchange server",
  499 => "Client Closed Request",
  500 => "Internal Server Error",
  501 => "Not Implemented",
  502 => "Bad Gateway",
  503 => "Service Unavailable",
  504 => "Gateway Timeout",
  505 => "HTTP Version Not Supported",
  506 => "Variant Also Negotiates",
  507 => "Insufficient Storage",
  508 => "Loop Detected",
  510 => "Not Extended",
  511 => "Network Authentication Required",
  598 => "Network read timeout error",
  599 => "Network connect timeout error"
}.freeze

class RecordNotFound < StandardError
end

module Test
  class Index < Hanami::Action
    def call(req, res)
      res[:xyz] = req.params[:name]
    end
  end
end

class CallAction < Hanami::Action
  def call(_req, res)
    res.status = 201
    res.body   = "Hi from TestAction!"
    res.headers.merge!("X-Custom" => "OK")
  end
end

class UncheckedErrorCallAction < Hanami::Action
  def call(_req, _res)
    raise
  end
end

class ErrorCallAction < Hanami::Action
  handle_exception RuntimeError => 500

  def call(_req, _res)
    raise
  end
end

class MyCustomError < StandardError; end
class ErrorCallFromInheritedErrorClass < Hanami::Action
  handle_exception StandardError => :handler

  def call(*)
    raise MyCustomError
  end

  private

  def handler(_req, res, *)
    res.status = 501
    res.body   = "An inherited exception occurred!"
  end
end

class ErrorCallFromInheritedErrorClassStack < Hanami::Action
  handle_exception StandardError => :standard_handler
  handle_exception MyCustomError => :handler

  def call(*)
    raise MyCustomError
  end

  private

  def handler(_req, res, *)
    res.status = 501
    res.body   = "MyCustomError was thrown"
  end

  def standard_handler(_req, res, *)
    res.status = 501
    res.body   = "An unknown error was thrown"
  end
end

class ErrorCallWithSymbolMethodNameAsHandlerAction < Hanami::Action
  handle_exception StandardError => :handler

  def call(*)
    raise StandardError
  end

  private

  def handler(_req, res, *)
    res.status = 501
    res.body   = "Please go away!"
  end
end

class ErrorCallWithStringMethodNameAsHandlerAction < Hanami::Action
  handle_exception StandardError => "standard_error_handler"

  def call(*)
    raise StandardError
  end

  private

  def standard_error_handler(_req, res, exception)
    res.status = 502
    res.body   = exception.message
  end
end

class ErrorCallWithUnsetStatusResponse < Hanami::Action
  handle_exception ArgumentError => "arg_error_handler"

  def call(*)
    raise ArgumentError
  end

  private

  def arg_error_handler(*)
  end
end

class ErrorCallWithSpecifiedStatusCodeAction < Hanami::Action
  handle_exception StandardError => 422

  def call(_req, _res)
    raise StandardError
  end
end

class BeforeMethodAction < Hanami::Action
  before :set_article, :reverse_article, :log_request
  append_before :add_first_name_to_logger, :add_last_name_to_logger
  prepend_before :add_title_to_logger

  def call(req, res)
  end

  private

  def set_article(*, res)
    res[:article] = "Bonjour!"
  end

  def reverse_article(*, res)
    res[:article].reverse!
  end

  def log_request(req, res)
    res[:arguments] = []
    res[:arguments] << req.class.name
    res[:arguments] << res.class.name
  end

  def add_first_name_to_logger(*, res)
    res[:logger] << "John"
  end

  def add_last_name_to_logger(*, res)
    res[:logger] << "Doe"
  end

  def add_title_to_logger(*, res)
    res[:logger] = []
    res[:logger] << "Mr."
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
  private

  def upcase_article
  end

  def set_article(req, res)
    res[:exposed_params] = req.params
    res[:article] = super(req, res) + req.params[:bang]
  end
end

class ErrorBeforeMethodAction < BeforeMethodAction
  private

  def set_article
    raise
  end
end

class HandledErrorBeforeMethodAction < BeforeMethodAction
  handle_exception RecordNotFound => 404

  private

  def set_article
    raise RecordNotFound.new
  end
end

class BeforeBlockAction < Hanami::Action
  before { |_, res|   res[:article] = "Good morning!" }
  before { |_, res|   res[:article].reverse! }
  before { |req, res| res[:arguments] = [req.class.name, res.class.name] }

  def call(req, res)
  end
end

class YieldBeforeBlockAction < BeforeBlockAction
  before { |req, res| res[:yielded_params] = req.params }
end

class AfterMethodAction < Hanami::Action
  after :set_egg, :scramble_egg, :log_request
  append_after :add_first_name_to_logger, :add_last_name_to_logger
  prepend_after :add_title_to_logger

  def call(*)
  end

  private

  def set_egg(*, res)
    res[:egg] = "Egg!"
  end

  def scramble_egg(*, res)
    res[:egg] = "gE!g"
  end

  def log_request(req, res)
    res[:arguments] = []
    res[:arguments] << req.class.name
    res[:arguments] << res.class.name
  end

  def add_first_name_to_logger(*, res)
    res[:logger] << "Jane"
  end

  def add_last_name_to_logger(*, res)
    res[:logger] << "Dixit"
  end

  def add_title_to_logger(*, res)
    res[:logger] = []
    res[:logger] << "Mrs."
  end
end

class AfterBlockAction < Hanami::Action
  after { |_, res| res[:egg] = "Coque" }
  after { |_, res| res[:egg].reverse! }
  after { |req, res| res[:arguments] = [req.class.name, res.class.name] }

  def call(*)
  end
end

class YieldAfterBlockAction < AfterBlockAction
  after { |req, res| res[:meaning_of_life_params] = req.params }

  def call(*)
  end
end

class MissingSessionAction < Hanami::Action
  def call(*)
    session
  end
end

class MissingFlashAction < Hanami::Action
  def call(*)
    flash
  end
end

class SessionAction < Hanami::Action
  include Hanami::Action::Session

  def call(req, res)
  end
end

class FlashAction < Hanami::Action
  include Hanami::Action::Session

  def call(*, res)
    res.flash[:error] = "ouch"
  end
end

class RedirectAction < Hanami::Action
  def call(*, res)
    res.redirect_to "/destination"
  end
end

class StatusRedirectAction < Hanami::Action
  def call(*, res)
    res.redirect_to "/destination", status: 301
  end
end

class SafeStringRedirectAction < Hanami::Action
  def call(*, res)
    location = Hanami::Utils::Escape::SafeString.new("/destination")
    res.redirect_to location
  end
end

class GetCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    res.body = res.cookies[:foo]
  end
end

class ChangeCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    res.body = res.cookies[:foo]
    res.cookies[:foo] = "baz"
  end
end

class GetDefaultCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    res.body          = ""
    res.cookies[:bar] = "foo"
  end
end

class GetOverwrittenCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    res.body          = ""
    res.cookies[:bar] = { value: "foo", domain: "hanamirb.com", path: "/action", secure: false, httponly: false }
  end
end

class GetAutomaticallyExpiresCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    res.cookies[:bar] = { value: "foo", max_age: 120 }
  end
end

class SetCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    res.body          = "yo"
    res.cookies[:foo] = "yum!"
  end
end

class SetCookiesWithOptionsAction < Hanami::Action
  include Hanami::Action::Cookies

  def initialize(expires: Time.now.utc)
    @expires = expires
  end

  def call(*, res)
    res.cookies[:kukki] = { value: "yum!", domain: "hanamirb.org", path: "/controller", expires: @expires, secure: true, httponly: true }
  end
end

class RemoveCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    res.cookies[:rm] = nil
  end
end

class IterateCookiesAction < Hanami::Action
  include Hanami::Action::Cookies

  def call(*, res)
    result = []
    res.cookies.each do |key, value|
      result << "'#{key}' has value '#{value}'"
    end

    res.body = result.join(", ")
  end
end

class ThrowCodeAction < Hanami::Action
  def call(req, *)
    halt req.params[:status].to_i, req.params[:message]
  end
end

class CatchAndThrowSymbolAction < Hanami::Action
  def call(_req, _res)
    catch :done do
      throw :done, 1
      raise "This code shouldn't be reachable"
    end
  end
end

class ThrowBeforeMethodAction < Hanami::Action
  before :authorize!
  before :set_body

  def call(_req, res)
    res.body = "Hello!"
  end

  private

  def authorize!
    halt 401
  end

  def set_body
    res.body = "Hi!"
  end
end

class ThrowBeforeBlockAction < Hanami::Action
  before { halt 401 }
  before { res.body = "Hi!" }

  def call(_req, res)
    res.body = "Hello!"
  end
end

class ThrowAfterMethodAction < Hanami::Action
  after :raise_timeout!
  after :set_body

  def call(_req, res)
    res.body = "Hello!"
  end

  private

  def raise_timeout!
    halt 408
  end

  def set_body
    res.body = "Later!"
  end
end

class ThrowAfterBlockAction < Hanami::Action
  after { halt 408 }
  after { res.body = "Later!" }

  def call(_req, res)
    res.body = "Hello!"
  end
end

class HandledExceptionAction < Hanami::Action
  handle_exception RecordNotFound => 404

  def call(_req, _res)
    raise RecordNotFound.new
  end
end

class DomainLogicException < StandardError
end

class GlobalHandledExceptionAction < Hanami::Action
  def call(_req, _res)
    raise DomainLogicException.new
  end
end

class UnhandledExceptionAction < Hanami::Action
  def call(_req, _res)
    raise RecordNotFound.new
  end
end

class ParamsAction < Hanami::Action
  def call(req, res)
    res.body = req.params.to_h.inspect
  end
end

class WhitelistedParamsAction < Hanami::Action
  class Params < Hanami::Action::Params
    params do
      required(:id).maybe
      required(:article).schema do
        required(:tags).each(:str?)
      end
    end
  end

  params Params

  def call(req, res)
    res.body = req.params.to_h.inspect
  end
end

class WhitelistedDslAction < Hanami::Action
  params do
    required(:username).filled
  end

  def call(req, res)
    res.body = req.params.to_h.inspect
  end
end

class WhitelistedUploadDslAction < Hanami::Action
  params do
    required(:id).maybe
    required(:upload).filled
  end

  def call(req, res)
    res.body = req.params.to_h.inspect
  end
end

class ParamsValidationAction < Hanami::Action
  params do
    required(:email).filled(:str?)
  end

  def call(req, *)
    halt 400 unless req.params.valid?
  end
end

class TestParams < Hanami::Action::Params
  params do
    required(:email).filled(format?: /\A.+@.+\z/)
    optional(:password).filled(:str?).confirmation
    required(:name).filled
    required(:tos).filled(:bool?)
    required(:age).filled(:int?)
    required(:address).schema do
      required(:line_one).filled
      required(:deep).schema do
        required(:deep_attr).filled(:str?)
      end
    end

    optional(:array).maybe do
      each do
        schema do
          required(:name).filled(:str?)
        end
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

class Root < Hanami::Action
  def call(req, res)
    res.body = req.params.to_h.inspect
    res.headers.merge!("X-Test" => "test")
  end
end

module About
  class Team < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
      res.headers.merge!("X-Test" => "test")
    end
  end

  class Contacts < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end
end

module Identity
  class Show < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class New < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Create < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Edit < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Update < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Destroy < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end
end

module Flowers
  class Index < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Show < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class New < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Create < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Edit < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Update < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end

  class Destroy < Hanami::Action
    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end
end

module Painters
  class Update < Hanami::Action
    params do
      required(:painter).schema do
        required(:first_name).filled(:str?)
        required(:last_name).filled(:str?)
        optional(:paintings).maybe do
          each do
            schema do
              required(:name).filled
            end
          end
        end
      end
    end

    def call(req, res)
      res.body = req.params.to_h.inspect
    end
  end
end

module Dashboard
  class Index < Hanami::Action
    include Hanami::Action::Session
    before :authenticate!

    def call(*, res)
      res.body = "User ID from session: #{res.session[:user_id]}"
    end

    private

    def authenticate!(*, res)
      halt 401 unless loggedin?(res)
    end

    def loggedin?(res)
      res.session.key?(:user_id)
    end
  end
end

module Sessions
  class Create < Hanami::Action
    include Hanami::Action::Session

    def call(*, res)
      res.session[:user_id] = 23
      res.redirect_to "/"
    end
  end

  class Destroy < Hanami::Action
    include Hanami::Action::Session

    def call(*, res)
      res.session[:user_id] = nil
    end
  end
end

class StandaloneSession < Hanami::Action
  include Hanami::Action::Session

  def call(*, res)
    res.session[:age] = Time.now.year - 1982
  end
end

module Glued
  class SendFile < Hanami::Action
    include Hanami::Action::Glue

    def call(_req, _res)
      send_file "test.txt"
    end
  end
end

class ArtistNotFound < StandardError
end

module App
  class CustomError < StandardError
  end

  class StandaloneAction < Hanami::Action
    handle_exception App::CustomError => 400

    def call(_req, _res)
      raise App::CustomError
    end
  end
end

module App2
  class CustomError < StandardError
  end

  module Standalone
    class Index < Hanami::Action
      handle_exception App2::CustomError => 400

      def call(_req, _res)
        raise App2::CustomError
      end
    end
  end
end

module MusicPlayer
  module Controllers
    module Authentication
      def self.included(action)
        action.class_eval do
          before do |_, res|
            res[:current_user] = current_user
          end
        end
      end

      private

      def current_user
        "Luca"
      end
    end

    class Dashboard
      class Index < Hanami::Action
        include Hanami::Action::Cookies
        include Hanami::Action::Session
        include MusicPlayer::Controllers::Authentication

        def call(_req, res)
          res.body = "Muzic!"
          res.headers["X-Frame-Options"] = "ALLOW FROM https://example.org"
        end
      end

      class Show < Hanami::Action
        include Hanami::Action::Cookies
        include Hanami::Action::Session
        include MusicPlayer::Controllers::Authentication

        def call(_req, _res)
          raise ArgumentError
        end
      end
    end

    module Artists
      class Index < Hanami::Action
        include Hanami::Action::Cookies
        include Hanami::Action::Session
        include MusicPlayer::Controllers::Authentication

        def call(_req, res)
          res.body = current_user
        end
      end

      class Show < Hanami::Action
        include Hanami::Action::Cookies
        include Hanami::Action::Session
        include MusicPlayer::Controllers::Authentication

        handle_exception ArtistNotFound => 404

        def call(_req, _res)
          raise ArtistNotFound
        end
      end
    end
  end

  class StandaloneAction < Hanami::Action
    include Hanami::Action::Cookies
    include Hanami::Action::Session
    include MusicPlayer::Controllers::Authentication

    def call(_req, _res)
      raise ArgumentError
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new do |config|
        config.handle_exception ArgumentError => 400
        config.default_headers(
          "X-Frame-Options" => "DENY"
        )
      end
    end
  end
end

class VisibilityAction < Hanami::Action
  include Hanami::Action::Cookies
  include Hanami::Action::Session

  def call(*, res)
    res.body   = "x"
    res.status = 201
    res.format = :json

    res.headers.merge!("X-Custom" => "OK", "Y-Custom" => "YO")
    res.session[:foo] = "bar"
  end
end

module SendFileTest
  module Files
    class Show < Hanami::Action
      def call(req, res)
        id = req.params[:id]

        # This if statement is only for testing purpose
        if id == "1"
          res.send_file Pathname.new("test.txt")
        elsif id == "2"
          res.send_file Pathname.new("hanami.png")
        elsif id == "3"
          res.send_file Pathname.new("Gemfile")
        elsif id == "100"
          res.send_file Pathname.new("unknown.txt")
        else
          # a more realistic example of globbing ':id(.:format)'

          resource = repository_dot_find_by_id(id)
          # this is usually 406, but I want to distinguish it from the 406 below.
          halt 400 unless resource
          extension = req.params[:format]

          case extension
          when "html"
            # in reality we'd render a template here, but as a test fixture, we'll simulate that answer
            # we should have also checked #accept? but w/e
            res.body = ::File.read(Pathname.new("spec/support/fixtures/#{resource.asset_path}.html"))
            res.status = 200
            res.format = format(:html)
          when "json", nil
            res.format = format(:json)
            res.send_file Pathname.new("#{resource.asset_path}.json")
          else
            halt 406
          end
        end
      end

      private

      Model = Struct.new(:id, :asset_path)

      def repository_dot_find_by_id(id)
        return nil unless id =~ /^\d+$/
        Model.new(id.to_i, "resource-#{id}")
      end
    end

    class UnsafeLocal < Hanami::Action
      def call(*, res)
        res.unsafe_send_file "Gemfile"
      end
    end

    class UnsafePublic < Hanami::Action
      def call(*, res)
        res.unsafe_send_file "spec/support/fixtures/test.txt"
      end
    end

    class UnsafeAbsolute < Hanami::Action
      def call(*, res)
        res.unsafe_send_file Pathname.new("Gemfile").realpath
      end
    end

    class UnsafeMissingLocal < Hanami::Action
      def call(*, res)
        res.unsafe_send_file "missing"
      end
    end

    class UnsafeMissingAbsolute < Hanami::Action
      def call(_req, res)
        res.unsafe_send_file Pathname.new(".").join("missing")
      end
    end

    class Flow < Hanami::Action
      def call(*, res)
        res.send_file Pathname.new("test.txt")
        res.redirect_to "/"
      end
    end

    class Glob < Hanami::Action
      def call(*)
        halt 202
      end
    end

    class BeforeCallback < Hanami::Action
      before :before_callback

      def call(*, res)
        res.send_file Pathname.new("test.txt")
      end

      private

      def before_callback(*, res)
        res.headers["X-Callbacks"] = "before"
      end
    end

    class AfterCallback < Hanami::Action
      after :after_callback

      def call(*, res)
        res.send_file Pathname.new("test.txt")
      end

      private

      def after_callback(*, res)
        res.headers["X-Callbacks"] = "after"
      end
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new do |config|
        config.public_directory = "spec/support/fixtures"
      end

      router = Hanami::Router.new(configuration: configuration, namespace: SendFileTest) do
        get "/files/flow",                    to: "files#flow"
        get "/files/unsafe_local",            to: "files#unsafe_local"
        get "/files/unsafe_public",           to: "files#unsafe_public"
        get "/files/unsafe_absolute",         to: "files#unsafe_absolute"
        get "/files/unsafe_missing_local",    to: "files#unsafe_missing_local"
        get "/files/unsafe_missing_absolute", to: "files#unsafe_missing_absolute"
        get "/files/before_callback",         to: "files#before_callback"
        get "/files/after_callback",          to: "files#after_callback"
        get "/files/:id(.:format)",           to: "files#show"
        get "/files/(*glob)",                 to: "files#glob"
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        run router
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

module HeadTest
  module Home
    class Index < Hanami::Action
      include Hanami::Action::Glue
      include Hanami::Action::Session

      def call(_req, res)
        res.body = "index"
      end
    end

    class Code < Hanami::Action
      include Hanami::Action::Cache
      include Hanami::Action::Glue
      include Hanami::Action::Session

      def call(req, res)
        content = "code"

        res.headers.merge!(
          "Allow"            => "GET, HEAD",
          "Content-Encoding" => "identity",
          "Content-Language" => "en",
          "Content-Length"   => content.length,
          "Content-Location" => "relativeURI",
          "Content-MD5"      => Digest::MD5.hexdigest(content),
          "Expires"          => "Thu, 01 Dec 1994 16:00:00 GMT",
          "Last-Modified"    => "Wed, 21 Jan 2015 11:32:10 GMT"
        )

        res.status = req.params[:code].to_i
        res.body   = "code"
      end
    end

    class Override < Hanami::Action
      include Hanami::Action::Glue
      include Hanami::Action::Session

      def call(_req, res)
        res.headers.merge!(
          "Last-Modified" => "Fri, 27 Nov 2015 13:32:36 GMT",
          "X-Rate-Limit"  => "4000",
          "X-No-Pass"     => "true"
        )

        res.status = 204
      end

      private

      def keep_response_header?(header)
        super || header == "X-Rate-Limit"
      end
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new do |config|
        config.default_headers(
          "X-Frame-Options" => "DENY"
        )
      end

      router = Hanami::Router.new(namespace: HeadTest, configuration: configuration) do
        get "/",           to: "home#index"
        get "/code/:code", to: "home#code"
        get "/override",   to: "home#override"
      end

      @app = Rack::Builder.new do
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run router
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

module FullStack
  module Controllers
    module Home
      class Index < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(*, res)
          res[:greeting] = "Hello"
        end
      end

      class Head < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(*, res)
          res.body = "foo"
        end
      end
    end

    module Books
      class Index < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(*)
        end
      end

      class Create < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        params do
          required(:title).filled(:str?)
        end

        def call(req, res)
          req.params.valid?

          res.redirect_to "/books"
        end
      end

      class Update < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

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

        def call(req, res)
          valid = req.params.valid?

          res.status = 201
          res.body = JSON.generate(
            symbol_access: req.params[:book][:author] && req.params[:book][:author][:name],
            valid: valid,
            errors: req.params.errors.to_h
          )
        end
      end
    end

    module Settings
      class Index < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(*)
        end
      end

      class Create < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(*, res)
          res.flash[:message] = "Saved!"
          res.redirect_to "/settings"
        end
      end
    end

    module Poll
      class Start < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(*, res)
          res.redirect_to "/poll/1"
        end
      end

      class Step1 < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(req, res)
          if req.env["REQUEST_METHOD"] == "GET"
            res.flash[:notice] = "Start the poll"
          else
            res.flash[:notice] = "Step 1 completed"
            res.redirect_to "/poll/2"
          end
        end
      end

      class Step2 < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(req, res)
          if req.env["REQUEST_METHOD"] == "POST"
            res.flash[:notice] = "Poll completed"
            res.redirect_to "/"
          end
        end
      end
    end

    module Users
      class Show < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        before :redirect_to_root
        after :set_body

        def call(*, res)
          res.body = "call method shouldn't be called"
        end

        private

        def redirect_to_root(*, res)
          res.redirect_to "/"
        end

        def set_body
          res.body = "after callback shouldn't be called"
        end
      end
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new

      routes = Hanami::Router.new(namespace: FullStack::Controllers, configuration: configuration) do
        get "/",     to: "home#index"
        get "/head", to: "home#head"
        resources :books, only: %i[index create update]

        get  "/settings", to: "settings#index"
        post "/settings", to: "settings#create"

        get "/poll", to: "poll#start"

        prefix "poll" do
          get  "/1", to: "poll#step1"
          post "/1", to: "poll#step1"
          get  "/2", to: "poll#step2"
          post "/2", to: "poll#step2"
        end

        prefix "users" do
          get "/1", to: "users#show"
        end
      end

      @renderer = Renderer.new
      @app      = Rack::Builder.new do
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end.to_app
    end

    def call(env)
      @renderer.render(env, @app.call(env))
    end
  end
end

class MethodInspectionAction < Hanami::Action
  def call(req, res)
    res.body = req.request_method
  end
end

class RackExceptionAction < Hanami::Action
  class TestException < ::StandardError
  end

  def call(_req, _res)
    raise TestException.new
  end
end

class HandledRackExceptionAction < Hanami::Action
  class TestException < ::StandardError
  end

  handle_exception TestException => 500

  def call(_req, _res)
    raise TestException.new
  end
end

class HandledRackExceptionSubclassAction < Hanami::Action
  class TestException < ::StandardError
  end

  class TestSubclassException < TestException
  end

  handle_exception TestException => 500

  def call(_req, _res)
    raise TestSubclassException.new
  end
end

module SessionWithCookies
  module Controllers
    module Home
      class Index < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Hanami::Action::Cookies

        def call(req, res)
        end
      end
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new

      resolver = EndpointResolver.new(configuration: configuration, namespace: SessionWithCookies::Controllers)
      routes   = Hanami::Router.new(resolver: resolver) do
        get "/", to: "home#index"
      end

      @renderer = Renderer.new
      @app = Rack::Builder.new do
        use Rack::Lint
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end.to_app
    end

    def call(env)
      @renderer.render(env, @app.call(env))
    end
  end
end

module SessionsWithoutCookies
  module Controllers
    module Home
      class Index < Hanami::Action
        include Hanami::Action::Glue
        include Hanami::Action::Session
        include Inspector

        def call(*)
        end
      end
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new

      routes = Hanami::Router.new(configuration: configuration, namespace: SessionsWithoutCookies::Controllers) do
        get "/", to: "home#index"
      end

      @renderer = Renderer.new
      @app      = Rack::Builder.new do
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end.to_app
    end

    def call(env)
      @renderer.render(env, @app.call(env))
    end
  end
end

module Mimes
  class Default < Hanami::Action
    def call(_req, res)
      res.body, = *format(res.content_type)
    end
  end

  class Custom < Hanami::Action
    def call(_req, res)
      res.format = format(:xml)
      res.body   = res.format
    end
  end

  class Latin < Hanami::Action
    def call(_req, res)
      res.charset = "latin1"
      res.format  = format(:html)
      res.body    = res.format
    end
  end

  class Accept < Hanami::Action
    def call(req, res)
      res.headers["X-AcceptDefault"] = req.accept?("application/octet-stream").to_s
      res.headers["X-AcceptHtml"]    = req.accept?("text/html").to_s
      res.headers["X-AcceptXml"]     = req.accept?("application/xml").to_s
      res.headers["X-AcceptJson"]    = req.accept?("text/json").to_s

      res.body, = *format(res.content_type)
    end
  end

  class CustomFromAccept < Hanami::Action
    accept :json, :custom

    def call(*, res)
      res.body, = *format(res.content_type)
    end
  end

  class Restricted < Hanami::Action
    accept :html, :json, :custom

    def call(_req, res)
      res.body, = *format(res.content_type)
    end
  end

  class NoContent < Hanami::Action
    def call(_req, res)
      res.status = 204
    end
  end

  class OverrideDefaultResponse < Hanami::Action
    def call(*, res)
      res.format = format(:xml)
    end

    private

    def default_response_format
      :json
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new do |config|
        config.format custom: "application/custom"
      end

      @router = Hanami::Router.new(configuration: configuration) do
        get "/",                   to: "mimes#default"
        get "/custom",             to: "mimes#custom"
        get "/accept",             to: "mimes#accept"
        get "/restricted",         to: "mimes#restricted"
        get "/latin",              to: "mimes#latin"
        get "/nocontent",          to: "mimes#no_content"
        get "/overwritten_format", to: "mimes#override_default_response"
        get "/custom_from_accept", to: "mimes#custom_from_accept"
      end
    end

    def call(env)
      @router.call(env)
    end
  end
end

module MimesWithDefault
  class Default < Hanami::Action
    accept :json

    def call(*, res)
      res.body, = *format(res.content_type)
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new do |config|
        config.default_response_format = :html
      end

      @router = Hanami::Router.new(configuration: configuration) do
        get "/default_and_accept", to: "mimes_with_default#default"
      end
    end

    def call(env)
      @router.call(env)
    end
  end
end

module RouterIntegration
  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new

      routes = Hanami::Router.new(configuration: configuration) do
        get "/",         to: "root"
        get "/team",     to: "about#team"
        get "/contacts", to: "about#contacts"

        resource  :identity
        resources :flowers
        resources :painters, only: [:update]
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        use Hanami::Middleware::BodyParser, :json
        run routes
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

module SessionIntegration
  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new
      resolver      = EndpointResolver.new(configuration: configuration)

      routes = Hanami::Router.new(resolver: resolver) do
        get    "/",       to: "dashboard#index"
        post   "/login",  to: "sessions#create"
        delete "/logout", to: "sessions#destroy"
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

module StandaloneSessionIntegration
  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new

      @app = Rack::Builder.new do
        use Rack::Lint
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run StandaloneSession.new(configuration: configuration)
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end

module Flash
  module Controllers
    module Home
      class Index < Hanami::Action
        include Hanami::Action::Session

        def call(req, res)
          res.flash[:hello] = "world"

          if req.env["REQUEST_METHOD"] == "GET"
            res.redirect_to "/books"
          else
            res.redirect_to "/print"
          end
        end
      end

      class Books < Hanami::Action
        include Hanami::Action::Session

        def call(_, res)
          res.body = "flash_empty: #{res.flash.empty?} flash: #{res.flash.inspect}"
        end
      end

      class Print < Hanami::Action
        include Hanami::Action::Session

        def call(_, res)
          res.body = res.flash[:hello]
        end
      end

      class EachRedirect < Hanami::Action
        include Hanami::Action::Session

        def call(_, res)
          res.flash[:hello] = "world"
          res.redirect_to "/each"
        end
      end

      class Each < Hanami::Action
        include Hanami::Action::Session

        def call(_, res)
          each_result = []
          res.flash.each { |type, message| each_result << [type, message] }
          res.body = "flash_each: #{each_result}"
        end
      end

      class MapRedirect < Hanami::Action
        include Hanami::Action::Session

        def call(_, res)
          res.flash[:hello] = "world"
          res.redirect_to "/map"
        end
      end

      class Map < Hanami::Action
        include Hanami::Action::Session

        def call(_, res)
          res.body = "flash_map: #{res.flash.map { |type, message| [type, message] }}"
        end
      end
    end
  end

  class Application
    def initialize # rubocop:disable Metrics/MethodLength
      configuration = Hanami::Controller::Configuration.new
      routes   = Hanami::Router.new(configuration: configuration, namespace: Flash::Controllers) do
        get "/",      to: "home#index"
        post "/",     to: "home#index"
        get "/print", to: "home#print"
        get "/books", to: "home#books"
        get "/map_redirect",   to: "home#map_redirect"
        get "/each_redirect",  to: "home#each_redirect"
        get "/map",            to: "home#map"
        get "/each",           to: "home#each"
      end

      @middleware = Rack::Builder.new do
        use Rack::Session::Cookie, secret: SecureRandom.hex(16)
        run routes
      end
    end

    def call(env)
      @middleware.call(env)
    end
  end
end
