require "hanami"
require "hanami/application_action"
require "hanami/action/cookies"

RSpec.describe "Application actions / Cookies", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
      end
    end

    Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)

    module Main
    end

    Hanami.application.register_slice :main, namespace: Main, root: "/path/to/app/slices/main"

    Hanami.init
  end

  subject(:action_class) {
    module Main
      class Action < Hanami::ApplicationAction
      end
    end

    Main::Action
  }

  context "default configuration" do
    it "has cookie support enabled" do
      expect(action_class.ancestors).to include Hanami::Action::Cookies
    end
  end

  context "custom cookie options given in application-level config" do
    subject(:application_hook) {
      proc do
        config.actions.cookies = {max_age: 300}
      end
    }

    it "has cookie support enabled" do
      expect(action_class.ancestors).to include Hanami::Action::Cookies
    end

    it "has the cookie options configured" do
      expect(action_class.config.cookies).to eq(max_age: 300)
    end
  end

  context "cookies disabled in application-level config" do
    subject(:application_hook) {
      proc do
        config.actions.cookies = nil
      end
    }

    it "does not have cookie support enabled" do
      expect(action_class.ancestors).not_to include Hanami::Action::Cookies
    end

    it "has no cookie options configured" do
      expect(action_class.config.cookies).to eq({})
    end
  end
end
