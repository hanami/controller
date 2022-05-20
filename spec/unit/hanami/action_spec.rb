# frozen_string_literal: true

require "hanami/devtools/unit"

RSpec.describe Hanami::Action do
  let(:action_class) { Class.new(described_class) }
  subject(:action) { action_class.new }

  describe ".configuration" do
    subject(:configuration) { action_class.configuration }

    it "returns an Action::Configuration object" do
      is_expected.to be_an_instance_of(Hanami::Action::Configuration)
    end

    it "is not frozen" do
      is_expected.not_to be_frozen
    end

    context "when inherited" do
      let(:superclass) { action_class }
      let(:subclass) { Class.new(action_class) }

      let(:superclass_configuration) { superclass.configuration }
      let(:subclass_configuration) { subclass.configuration }

      before do
        superclass_configuration.formats = {"text/html" => :html}
      end

      it "inherits the configuration from the superclass" do
        expect(subclass_configuration.formats).to eq("text/html" => :html)
      end

      it "can be changed on the subclass without affecting the superclass" do
        subclass_configuration.formats = {"custom/format" => :custom}

        expect(subclass_configuration.formats).to eq("custom/format" => :custom)
        expect(superclass_configuration.formats).to eq("text/html" => :html)
      end
    end
  end

  describe ".config" do
    subject(:config) { action_class.config }

    it "is an alias for the configuration" do
      is_expected.to be action_class.configuration
    end
  end

  describe ".new" do
    let(:action_class) {
      Class.new(Hanami::Action) do
        attr_reader :args, :kwargs, :block

        def initialize(*args, **kwargs, &block)
          @args = args
          @kwargs = kwargs
          @block = block
        end
      end
    }

    it "instantiates a frozen action" do
      expect(action).to be_frozen
    end

    it "forwards arguments to `#initialize`" do
      action = action_class.new(1, 2, 3, a: 4, b: 5) { 6 }

      expect(action.args).to eq([1, 2, 3])
      expect(action.kwargs).to eq({a: 4, b: 5})
      expect(action.block.call).to eq(6)
    end
  end

  describe "#call" do
    it "calls an action" do
      response = CallAction.new.call({})

      expect(response.status).to  eq(201)
      expect(response.headers).to eq("Content-Length" => "19", "Content-Type" => "application/octet-stream; charset=utf-8", "X-Custom" => "OK")
      expect(response.body).to    eq(["Hi from TestAction!"])
    end

    context "when an exception isn't handled" do
      it "should raise an actual exception" do
        expect { UncheckedErrorCallAction.new.call({}) }.to raise_error(RuntimeError)
      end
    end

    context "when an exception is handled" do
      it "returns an HTTP 500 status code when an exception is raised" do
        response = ErrorCallAction.new.call({})

        expect(response.status).to eq(500)
        expect(response.body).to   eq(["Internal Server Error"])
      end

      it "handles inherited exception with specified method" do
        response = ErrorCallFromInheritedErrorClass.new.call({})

        expect(response.status).to eq(501)
        expect(response.body).to   eq(["An inherited exception occurred!"])
      end

      it "handles exception with specified method" do
        response = ErrorCallFromInheritedErrorClassStack.new.call({})

        expect(response.status).to eq(501)
        expect(response.body).to   eq(["MyCustomError was thrown"])
      end

      it "handles exception with specified method (symbol)" do
        response = ErrorCallWithSymbolMethodNameAsHandlerAction.new.call({})

        expect(response.status).to eq(501)
        expect(response.body).to   eq(["Please go away!"])
      end

      it "handles exception with specified method (string)" do
        response = ErrorCallWithStringMethodNameAsHandlerAction.new.call({})

        expect(response.status).to eq(502)
        expect(response.body).to   eq(["StandardError"])
      end

      it "handles exception with specified status code" do
        response = ErrorCallWithSpecifiedStatusCodeAction.new.call({})

        expect(response.status).to eq(422)
        expect(response.body).to   eq(["Unprocessable Entity"])
      end

      it "returns a successful response if the code and status aren't set" do
        response = ErrorCallWithUnsetStatusResponse.new.call({})

        expect(response.status).to eq(200)
        expect(response.body).to   eq([])
      end
    end

    context "when setting res.session with sessions disabled" do
      it "raises an informative exception" do
        expected = Hanami::Action::MissingSessionError
        expect { MissingResponseSessionAction.new.call({}) }.to raise_error(
          expected,
          "To use `Hanami::Action::Response#session`, add `include Hanami::Action::Session`."
        )
      end
    end

    context "when setting res.flash with sessions disabled" do
      it "raises an informative exception" do
        expected = Hanami::Action::MissingSessionError
        expect { MissingResponseFlashAction.new.call({}) }.to raise_error(
          expected,
          "To use `Hanami::Action::Response#flash`, add `include Hanami::Action::Session`."
        )
      end
    end

    context "when accessing req.session with sessions disabled" do
      it "raises an informative exception" do
        expected = Hanami::Action::MissingSessionError
        expect { MissingRequestSessionAction.new.call({}) }.to raise_error(
          expected,
          "To use `Hanami::Action::Request#session`, add `include Hanami::Action::Session`."
        )
      end
    end
  end

  describe "#name" do
    it "returns action name" do
      subject = FullStack::Controllers::Home::Index.new
      expect(subject.name).to eq("full_stack.controllers.home.index")
    end

    it "returns nil for anonymous classes" do
      subject = Class.new(Hanami::Action).new
      expect(subject.name).to be(nil)
    end
  end

  describe "request" do
    it "gets a Rack-like request object" do
      action_class = Class.new(Hanami::Action) do
        def handle(req, res)
          res[:request] = req
        end
      end

      action = action_class.new
      env = Rack::MockRequest.env_for("http://example.com/foo")
      response = action.call(env)

      expect(response[:request].path).to eq("/foo")
    end
  end

  describe "Method visibility" do
    let(:action) { VisibilityAction.new }

    it "ensures that protected and private methods can be safely invoked by developers" do
      response = action.call({})

      expect(response.status).to be(201)

      expect(response.headers.fetch("X-Custom")).to eq("OK")
      expect(response.headers.fetch("Y-Custom")).to eq("YO")

      expect(response.body).to eq(["x"])
    end
  end
end
