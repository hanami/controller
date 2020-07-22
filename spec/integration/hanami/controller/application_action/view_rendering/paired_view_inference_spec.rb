require "hanami"

RSpec.describe "Application actions / View rendering / Paired view inference", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
      end
    end

    module Main; end
    Hanami.application.register_slice :main, namespace: Main, root: "/path/to/app/slices/main"

    Hanami.init
  end

  let(:action_class) {
    module Main
      module Actions
        module Articles
          class Index < Hanami::Action
          end
        end
      end
    end
    Main::Actions::Articles::Index
  }

  let(:action) { action_class.new }

  context "Paired view exists" do
    let(:view) { double(:view) }

    before do
      Main::Slice.register "views.articles.index", view
    end

    it "auto-injects a paired view from a matching container identifier" do
      expect(action.view).to be view
    end
  end

  context "No paired view exists" do
    it "does not auto-inject any view" do
      expect(action.view).to be_nil
    end
  end
end
