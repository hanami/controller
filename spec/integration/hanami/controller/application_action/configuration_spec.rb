# frozen_string_literal: true

require "hanami"
require "hanami/action"

RSpec.describe "Application actions / Configuration", :application_integration do
  describe "Inside Hanami app" do
    before do
      module TestApp
        class Application < Hanami::Application
          config.actions.default_response_format = :json
        end
      end

      module Main
      end

      Hanami.application.register_slice :main, namespace: Main, root: "/path/to/app/slices/main"
      Hanami.init
    end

    let(:action_class) {
      module Main
        class Action < Hanami::Action
        end
      end

      Main::Action
    }

    subject(:configuration) { action_class.config }

    it "applies 'config.actions' configuration from the application" do
      expect(configuration.default_response_format).to eq :json
    end
  end
end
