# frozen_string_literal: true

require "hanami"
require "hanami/action"

RSpec.describe "Application actions", :application_integration do
  describe "Outside Hanami app" do
    subject(:action) { Class.new(Hanami::Action).new }

    before do
      allow(Hanami).to receive(:respond_to?).with(:application?) { nil }
    end

    it "is not an application action" do
      expect(action.class.ancestors).not_to include(a_kind_of(Hanami::Action::ApplicationAction))
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

    let(:action_class) {
      module Main
        class Action < Hanami::Action
        end
      end

      Main::Action
    }

    subject(:action) { action_class.new }

    it "is an application action" do
      expect(action.class.ancestors).to include(a_kind_of(Hanami::Action::ApplicationAction))
    end
  end
end
