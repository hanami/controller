# frozen_string_literal: true

require "hanami"
require "hanami/application_action"

RSpec.describe "Application actions", :application_integration do
  subject(:action) { action_class.new }

  describe "Outside Hanami app" do
    let(:action_class) { Class.new(Hanami::ApplicationAction) }

    before do
      allow(Hanami).to receive(:application) { nil }
    end

    it "raises error on definition" do
      expect { action_class }.to raise_error(ArgumentError).
        with_message("ApplicationAction must be defined within a Hanami::Application")
    end
  end

  describe "Inside Hanami app" do
    before do
      module TestApp
        class Application < Hanami::Application
        end
      end

      module Main
      end

      Hanami.application.register_slice :main, namespace: Main, root: "/path/to/app/slices/main"
      Hanami.init
    end

    let(:action_class) do
      module Main
        class Action < Hanami::ApplicationAction
        end
      end

      Main::Action
    end

    it "is an application action" do
      expect(action.class.superclass).to eq(Hanami::ApplicationAction)
    end

    it "has custom inspector" do
      expect(action.inspect).to eq("#<Main::Action[main]>")
    end
  end
end
