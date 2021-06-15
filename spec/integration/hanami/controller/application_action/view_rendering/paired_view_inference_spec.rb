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

  let(:action) { action_class.new }

  context "Regular action" do
    shared_examples "action with view inference" do
      context "Paired view exists" do
        let(:view) { double(:view) }

        before do
          Main::Slice.register "views.articles.index", view
        end

        it "auto-injects a paired view from a matching container identifier" do
          expect(action.view).to be view
        end

        context "Another view explicitly auto-injected" do
          let(:action_class) {
            module Main
              module Actions
                module Articles
                  class Index < Hanami::Action
                    include Deps[view: "views.articles.custom"]
                  end
                end
              end
            end
            Main::Actions::Articles::Index
          }

          let(:explicit_view) { double(:explicit_view) }

          before do
            Main::Slice.register "views.articles.custom", explicit_view
          end

          it "respects the explicitly auto-injected view" do
            expect(action.view).to be explicit_view
          end
        end
      end

      context "No paired view exists" do
        it "does not auto-inject any view" do
          expect(action.view).to be_nil
        end
      end
    end

    context "Direct Hanami::View subclass" do
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

      it_behaves_like "action with view inference"
    end

    context "Subclass of shared superclass" do
      let(:action_class) {
        module Main
          class Action < Hanami::Action
          end

          module Actions
            module Articles
              class Index < Action
              end
            end
          end
        end
        Main::Actions::Articles::Index
      }

      it_behaves_like "action with view inference"
    end
  end

  context "RESTful action" do
    let(:action_class) {
      module Main
        module Actions
          module Articles
            class Create < Hanami::Action
            end
          end
        end
      end
      Main::Actions::Articles::Create
    }

    let(:direct_paired_view) { double(:direct_paired_view) }
    let(:alternative_paired_view) { double(:alternative_paired_view) }

    context "Direct paired view exists" do
      before do
        Main::Slice.register "views.articles.create", direct_paired_view
        Main::Slice.register "views.articles.new", alternative_paired_view
      end

      it "auto-injects the directly paired view" do
        expect(action.view).to be direct_paired_view
      end
    end

    context "Alternative paired view exists" do
      before do
        Main::Slice.register "views.articles.new", alternative_paired_view
      end

      it "auto-injects the alternative paired view" do
        expect(action.view).to be alternative_paired_view
      end
    end
  end


end
