# frozen_string_literal: true

require "hanami"
require "hanami/action"

RSpec.describe "Application actions / View integration", :application_integration do
  describe "Outside Hanami app" do
    subject(:action) { Class.new(Hanami::Action).new }

    before do
      allow(Hanami).to receive(:respond_to?).with(:application?) { nil }
    end

    it "does not provide view integration methods" do
      expect(action).not_to respond_to(:view_context)
    end
  end

  describe "Inside Hanami app" do
    before do
      module TestApp
        class Application < Hanami::Application
        end
      end

      Hanami.application.register_slice :main
      Hanami.application.tap(&pre_app_prepare_hook)
      Hanami.application.prepare
    end

    let(:pre_app_prepare_hook) { proc { } }

    let(:action_module) { Main }

    let(:action_class) {
      eval <<~RUBY
        module #{action_module}
          class Action < Hanami::Action
          end
        end

        #{action_module}::Action
      RUBY
    }

    subject(:action) { action_class.new(**action_args) }
    let(:action_args) { {} }

    describe "#view_context" do
      subject(:view_context) { action.view_context }

      context "Explicitly injected object" do
        let(:view_context) { double(:view_context) }
        let(:action_args) { {view_context: view_context} }

        it "returns the injected object" do
          is_expected.to eql view_context
        end
      end

      context "Action inside slice" do
        let(:action_module) { Main }

        context "no view context registered" do
          it "is nil" do
            is_expected.to be_nil
          end
        end

        context "default view context identifier" do
          context "view context registered in slice" do
            let(:slice_view_context) { double(:slice_view_context) }

            before do
              Main::Slice.register "view.context", slice_view_context
            end

            it "is the slice's view context" do
              is_expected.to eql slice_view_context
            end
          end

          context "view context registered in application" do
            let(:application_view_context) { double(:application_view_context) }

            before do
              Hanami.application.register "view.context", application_view_context
            end

            it "is the applications's view context" do
              is_expected.to eql application_view_context
            end
          end
        end

        context "custom view context identifier" do
          let(:custom_view_context) { double(:custom_view_context) }

          let(:pre_app_prepare_hook) {
            proc do |app|
              app.config.actions.view_context_identifier = "view.custom_context"
            end
          }

          before do
            Main::Slice.register "view.custom_context", custom_view_context
          end

          it "is the context registered with the custom identifier" do
            is_expected.to eql custom_view_context
          end
        end
      end

      context "Action inside application" do
        let(:action_module) { TestApp }

        context "no view context registered" do
          it "is nil" do
            is_expected.to be_nil
          end
        end

        context "view context registered in application" do
          let(:application_view_context) { double(:application_view_context) }

          before do
            Hanami.application.register "view.context", application_view_context
          end

          it "is the applications's view context" do
            is_expected.to eql application_view_context
          end
        end
      end
    end

    describe "#view_options" do
      subject(:view_options) { action.send(:view_options, req, res) }
      let(:req) { double(:req) }
      let(:res) { double(:res) }

      context "without view context" do
        it "is an empty hash" do
          is_expected.to eq({})
        end
      end

      context "with view context" do
        let(:initial_view_context) { double(:initial_view_context) }
        let(:action_args) { {view_context: initial_view_context} }

        context "default #view_context_options" do
          let(:request_view_context) { double(:request_view_context) }

          before do
            allow(initial_view_context).to receive(:with).with(
              request: req,
              response: res,
            ) { request_view_context }
          end

          it "is the view context with the request and response provided" do
            is_expected.to eq(context: request_view_context)
          end
        end

        context "custom #view_context_options" do
          let(:custom_view_context) { double(:custom_view_context)}

          before do
            action_class.class_eval do
              def view_context_options(req, res)
                {custom_option: "custom option"}
              end
            end

            allow(initial_view_context).to receive(:with).with(
              custom_option: "custom option"
            ) { custom_view_context }
          end

          it "is the view context with the custom options provided" do
            is_expected.to eq(context: custom_view_context)
          end
        end

        context "specialized method (calling super) defined in action class" do
          let(:request_view_context) { double(:request_view_context) }

          before do
            allow(initial_view_context).to receive(:with).with(
              request: req,
              response: res,
            ) { request_view_context }

            action_class.class_eval do
              def view_options(req, res)
                super.merge(extra_option: "extra option")
              end
            end
          end

          it "includes the options provided by the specialized method" do
            is_expected.to eq(context: request_view_context, extra_option: "extra option")
          end
        end
      end
    end
  end
end


