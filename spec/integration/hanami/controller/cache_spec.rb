require 'hanami/router'
require 'hanami/action/cache'

module CacheControl
  class Default < Hanami::Action
    include Hanami::Action::Cache

    cache_control :public, max_age: 600

    def call(*)
    end
  end

  class Overriding < Hanami::Action
    include Hanami::Action::Cache

    cache_control :public, max_age: 600

    def call(_, res)
      res.cache_control :private
    end
  end

  class Symbol < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.cache_control :private
    end
  end

  class Symbols < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.cache_control :private, :no_cache, :no_store
    end
  end

  class Hash < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.cache_control :public, :no_store, max_age: 900, s_maxage: 86_400, min_fresh: 500, max_stale: 700
    end
  end

  class PrivatePublic < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.cache_control :private, :public
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new
      routes = Hanami::Router.new(configuration: configuration) do
        get '/default',            to: 'cache_control#default'
        get '/overriding',         to: 'cache_control#overriding'
        get '/symbol',             to: 'cache_control#symbol'
        get '/symbols',            to: 'cache_control#symbols'
        get '/hash',               to: 'cache_control#hash'
        get '/private-and-public', to: 'cache_control#private_public'
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        run routes
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

module Web
  module Controllers
    module Home
      class Index < Hanami::Action
        def call(*)
        end
      end
    end
  end
end

module Admin
  module Controllers
    module Home
      class Index < Hanami::Action
        def call(*)
        end
      end
    end
  end
end

module Expires
  class Default < Hanami::Action
    include Hanami::Action::Cache

    expires 900, :public, :no_cache

    def call(*)
    end
  end

  class Overriding < Hanami::Action
    include Hanami::Action::Cache

    expires 900, :public, :no_cache

    def call(_, res)
      res.expires 600, :private
    end
  end

  class Symbol < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.expires 900, :private
    end
  end

  class Symbols < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.expires 900, :private, :no_cache, :no_store
    end
  end

  class Hash < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.expires 900, :public, :no_store, s_maxage: 86_400, min_fresh: 500, max_stale: 700
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new
      routes = Hanami::Router.new(configuration: configuration) do
        get '/default',              to: 'expires#default'
        get '/overriding',           to: 'expires#overriding'
        get '/symbol',               to: 'expires#symbol'
        get '/symbols',              to: 'expires#symbols'
        get '/hash',                 to: 'expires#hash'
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        run routes
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

module ConditionalGet
  class Etag < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.fresh etag: 'updated'
    end
  end

  class LastModified < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.fresh last_modified: Time.now
    end
  end

  class EtagLastModified < Hanami::Action
    include Hanami::Action::Cache

    def call(_, res)
      res.fresh etag: 'updated', last_modified: Time.now
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new
      routes = Hanami::Router.new(configuration: configuration) do
        get '/etag',               to: 'conditional_get#etag'
        get '/last-modified',      to: 'conditional_get#last_modified'
        get '/etag-last-modified', to: 'conditional_get#etag_last_modified'
      end

      @app = Rack::Builder.new do
        # FIXME: enable again Rack::Lint. It looks like there was some problems
        # with the headers that we never discovered, because this is the first
        # time we add Lint to these tests.
        #
        # use Rack::Lint
        run routes
      end
    end

    def call(env)
      @app.call(env)
    end
  end
end

RSpec.describe "HTTP Cache" do
  describe "Cache control" do
    let(:app) { Rack::MockRequest.new(CacheControl::Application.new) }

    context "default cache control" do
      it "returns default Cache-Control headers" do
        response = app.get("/default")
        expect(response.headers.fetch("Cache-Control")).to eq("public, max-age=600")
      end

      context "but some action overrides it" do
        it "returns more specific Cache-Control headers" do
          response = app.get("/overriding")
          expect(response.headers.fetch("Cache-Control")).to eq("private")
        end
      end
    end

    it "accepts a Symbol" do
      response = app.get("/symbol")
      expect(response.headers.fetch("Cache-Control")).to eq("private")
    end

    it "accepts multiple Symbols" do
      response = app.get("/symbols")
      expect(response.headers.fetch("Cache-Control")).to eq("private, no-cache, no-store")
    end

    it "accepts a Hash" do
      response = app.get("/hash")
      expect(response.headers.fetch("Cache-Control")).to eq("public, no-store, max-age=900, s-maxage=86400, min-fresh=500, max-stale=700")
    end

    context "private and public directives" do
      it "ignores public directive" do
        response = app.get("/private-and-public")
        expect(response.headers.fetch("Cache-Control")).to eq("private")
      end
    end
  end

  describe "Expires" do
    let(:app) { Rack::MockRequest.new(Expires::Application.new) }

    context "default cache control" do
      it "returns default Cache-Control headers" do
        response = app.get("/default")
        expect(response.headers.fetch("Expires")).to eq((Time.now + 900).httpdate)
        expect(response.headers.fetch("Cache-Control")).to eq("public, no-cache, max-age=900")
      end

      context "but some action overrides it" do
        it "returns more specific Cache-Control headers" do
          response = app.get("/overriding")
          expect(response.headers.fetch("Expires")).to eq((Time.now + 600).httpdate)
          expect(response.headers.fetch("Cache-Control")).to eq("private, max-age=600")
        end
      end
    end

    it "accepts a Symbol" do
      now = Time.now
      # FIXME: remove `at_least`
      expect(Time).to receive(:now).at_least(:once).and_return(now)

      response = app.get("/symbol")
      expect(response.headers.fetch("Expires")).to eq((now + 900).httpdate)
      expect(response.headers.fetch("Cache-Control")).to eq("private, max-age=900")
    end

    it "accepts multiple Symbols" do
      now = Time.now
      # FIXME: remove `at_least`
      expect(Time).to receive(:now).at_least(:once).and_return(now)

      response = app.get("/symbols")
      expect(response.headers.fetch("Expires")).to eq((now + 900).httpdate)
      expect(response.headers.fetch("Cache-Control")).to eq("private, no-cache, no-store, max-age=900")
    end

    it "accepts a Hash" do
      now = Time.now
      # FIXME: remove `at_least`
      expect(Time).to receive(:now).at_least(:once).and_return(now)

      response = app.get("/hash")
      expect(response.headers.fetch("Expires")).to eq((now + 900).httpdate)
      expect(response.headers.fetch("Cache-Control")).to eq("public, no-store, s-maxage=86400, min-fresh=500, max-stale=700, max-age=900")
    end
  end

  describe "Fresh" do
    let(:app) { Rack::MockRequest.new(ConditionalGet::Application.new) }

    describe "#etag" do
      context "when etag matches HTTP_IF_NONE_MATCH header" do
        it "halts 304 not modified" do
          response = app.get("/etag", "HTTP_IF_NONE_MATCH" => "updated")
          expect(response.status).to be(304)
        end

        it "keeps the same etag header" do
          response = app.get("/etag", "HTTP_IF_NONE_MATCH" => "outdated")
          expect(response.headers.fetch("ETag")).to eq("updated")
        end
      end

      context "when etag does not match HTTP_IF_NONE_MATCH header" do
        it "completes request" do
          response = app.get("/etag", "HTTP_IF_NONE_MATCH" => "outdated")
          expect(response.status).to be(200)
        end

        it "returns etag header" do
          response = app.get("/etag", "HTTP_IF_NONE_MATCH" => "outdated")
          expect(response.headers.fetch("ETag")).to eq("updated")
        end
      end
    end

    describe "#last_modified" do
      let(:modified_since) { Time.new(2014, 1, 8, 0, 0, 0) }
      let(:last_modified)  { Time.new(2014, 2, 8, 0, 0, 0) }

      context "when last modified is less than or equal to HTTP_IF_MODIFIED_SINCE header" do
        before do
          expect(Time).to receive(:now).at_least(:once).and_return(modified_since)
        end

        it "halts 304 not modified" do
          response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => modified_since.httpdate)
          expect(response.status).to be(304)
        end

        it "keeps the same IfModifiedSince header" do
          response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => modified_since.httpdate)
          expect(response.headers.fetch("Last-Modified")).to eq(modified_since.httpdate)
        end
      end

      context "when last modified is bigger than HTTP_IF_MODIFIED_SINCE header" do
        before do
          expect(Time).to receive(:now).at_least(:once).and_return(last_modified)
        end

        it "completes request" do
          response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => modified_since.httpdate)
          expect(response.status).to be(200)
        end

        it "returns etag header" do
          response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => modified_since.httpdate)
          expect(response.headers.fetch("Last-Modified")).to eq(last_modified.httpdate)
        end
      end

      context "when last modified is empty string" do
        context "and HTTP_IF_MODIFIED_SINCE empty" do
          it "completes request" do
            response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => "")
            expect(response.status).to be(200)
          end

          it "stays the Last-Modified header as time" do
            expect(Time).to receive(:now).and_return(modified_since)

            response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => "")
            expect(response.headers.fetch("Last-Modified")).to eq(modified_since.httpdate)
          end
        end

        context "and HTTP_IF_MODIFIED_SINCE contain space string" do
          it "completes request" do
            response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => " ")
            expect(response.status).to be(200)
          end

          it "stays the Last-Modified header as time" do
            expect(Time).to receive(:now).and_return(modified_since)

            response = app.get("/last-modified", "HTTP_IF_MODIFIED_SINCE" => " ")
            expect(response.headers.fetch("Last-Modified")).to eq(modified_since.httpdate)
          end
        end

        context "and HTTP_IF_NONE_MATCH empty" do
          it "completes request" do
            response = app.get("/last-modified", "HTTP_IF_NONE_MATCH" => "")
            expect(response.status).to be(200)
          end

          it "doesn't send Last-Modified" do
            expect(Time).to receive(:now).and_return(modified_since)

            response = app.get("/last-modified", "HTTP_IF_NONE_MATCH" => "")
            expect(response.headers).to_not have_key("Last-Modified")
          end
        end

        context "and HTTP_IF_NONE_MATCH contain space string" do
          it "completes request" do
            response = app.get("/last-modified", "HTTP_IF_NONE_MATCH" => " ")
            expect(response.status).to be(200)
          end

          it "doesn't send Last-Modified" do
            expect(Time).to receive(:now).and_return(modified_since)

            response = app.get("/last-modified", "HTTP_IF_NONE_MATCH" => " ")
            expect(response.headers).to_not have_key("Last-Modified")
          end
        end
      end
    end
  end
end
