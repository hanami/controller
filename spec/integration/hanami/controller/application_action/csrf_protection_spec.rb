require "hanami"
require "hanami/action"
require "hanami/action/csrf_protection"

RSpec.describe "Application actions / CSRF protection", :application_integration do
  describe "Outside Hanami app" do
    subject(:action_class) { Class.new(Hanami::Action) }

    before do
      allow(Hanami).to receive(:respond_to?).with(:application?) { nil }
    end

    it "does not have CSRF protection enabled" do
      expect(action_class.ancestors).not_to include Hanami::Action::CSRFProtection
    end
  end

  describe "Inside Hanami app" do
    before do
      application_class

      module Main
      end

      Hanami.application.register_slice :main, namespace: Main, root: "/path/to/app/slices/main"
      Hanami.prepare
    end

    subject(:action_class) {
      module Main
        class Action < Hanami::Action
        end
      end

      Main::Action
    }

    context "application sessions enabled" do
      context "CSRF protection not explicitly configured" do
        subject(:application_class) {
          module TestApp
            class Application < Hanami::Application
              config.actions.sessions = :cookie, {secret: "abc123"}
            end
          end
        }

        it "has CSRF protection enabled" do
          expect(action_class.ancestors).to include Hanami::Action::CSRFProtection
        end
      end

      context "CSRF protection explicitly disabled" do
        subject(:application_class) {
          module TestApp
            class Application < Hanami::Application
              config.sessions = :cookie, {secret: "abc123"}
              config.actions.csrf_protection = false
            end
          end
        }

        it "does not have CSRF protection enabled" do
          expect(action_class.ancestors).not_to include Hanami::Action::CSRFProtection
        end
      end
    end

    context "application sessions not enabled" do
      subject(:application_class) {
        module TestApp
          class Application < Hanami::Application
          end
        end
      }

      it "does not have CSRF protection enabled" do
        expect(action_class.ancestors).not_to include Hanami::Action::CSRFProtection
      end
    end
  end
end
