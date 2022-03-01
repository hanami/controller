require "hanami"
require "hanami/action"
require "hanami/action/cookies"

RSpec.describe "Application actions / Cookies", :application_integration do
  describe "Outside Hanami app" do
    subject(:action_class) { Class.new(Hanami::Action) }

    before do
      allow(Hanami).to receive(:respond_to?).with(:application?) { nil }
    end

    it "does not have cookies enabled" do
      expect(action_class.ancestors).not_to include Hanami::Action::Cookies
    end
  end

  describe "Inside Hanami app" do
    before do
      module TestApp
        class Application < Hanami::Application
        end
      end

      Hanami.application.instance_eval(&application_hook) if respond_to?(:application_hook)
      Hanami.application.register_slice :main
      Hanami.application.prepare
    end

    subject(:action_class) {
      module Main
        class Action < Hanami::Action
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
end
