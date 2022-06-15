# frozen_string_literal: true

RSpec.describe Hanami::Action::Response do
  describe "#render" do
    subject(:response) {
      described_class.new(
        request: request,
        action: "action",
        configuration: Hanami::Action::Configuration.new, env: env,
        view_options: view_options
      )
    }

    let(:request) { double(:request) }
    let(:env) { { "REQUEST_METHOD" => "GET" } }

    let(:view) { spy(:view) }

    before do
      rendered = double(:rendered, to_str: "view output")

      if expected_view_args.any?
        allow(view).to receive(:call).with(**expected_view_args) { rendered }
      else
        args = RUBY_VERSION >= "2.7" ? no_args : {}
        allow(view).to receive(:call).with(args) { rendered }
      end
    end

    shared_examples "rendered view" do
      it "calls the view with the generated view_options and sets its string value as the body" do
        response.render view, **render_args
        expect(response.body).to eq ["view output"]
      end
    end

    context "view_options provided to response" do
      let(:view_options) { double(:view_options) }
      let(:context) { double(:context) }

      before do
        allow(view_options).to receive(:call).with(request, response) {
          {context: context}
        }
      end

      context "with render arguments" do
        let(:render_args) { {extra_args: "here"} }
        let(:expected_view_args) { {context: context, extra_args: "here"} }
        it_behaves_like "rendered view"
      end

      context "without render arguments" do
        let(:render_args) { {} }
        let(:expected_view_args) { {context: context} }
        it_behaves_like "rendered view"
      end
    end

    context "no view_options provided" do
      let(:view_options) { nil }

      context "with render arguments" do
        let(:render_args) { {extra_args: "here"} }
        let(:expected_view_args) { {extra_args: "here"} }
        it_behaves_like "rendered view"
      end

      context "without render arguments" do
        let(:render_args) { {} }
        let(:expected_view_args) { {} }
        it_behaves_like "rendered view"
      end
    end
  end

  describe "#renderable?" do
    subject {
      described_class.new(
        request: double(:request),
        action: "action",
        configuration: Hanami::Action::Configuration.new, env: env
      )
    }
    let(:env) { { "REQUEST_METHOD" => "GET" } }

    context "when body isn't set" do
      it "returns true" do
        expect(subject.renderable?).to be(true)
      end
    end

    context "when body is set" do
      before do
        subject.body = "OK"
      end

      it "returns false" do
        expect(subject.renderable?).to be(false)
      end

      context "and HEAD request" do
        let(:env) { { "REQUEST_METHOD" => "HEAD" } }

        it "returns false" do
          expect(subject.renderable?).to be(false)
        end
      end
    end

    context "when HEAD request" do
      let(:env) { { "REQUEST_METHOD" => "HEAD" } }

      it "returns false" do
        expect(subject.renderable?).to be(false)
      end

      context "and sending file" do
        it "returns false" do
          subject.unsafe_send_file(__FILE__)
          expect(subject.renderable?).to be(false)
        end
      end
    end

    context "when sending file" do
      before do
        subject.unsafe_send_file(__FILE__)
      end

      it "returns false" do
        expect(subject.renderable?).to be(false)
      end
    end
  end

  describe "#allow_redirect?" do
    subject {
      described_class.new(
        request: double(:request),
        action: "action",
        configuration: Hanami::Action::Configuration.new, env: env
      )
    }
    let(:env) { { "REQUEST_METHOD" => "GET" } }

    context "when body isn't set" do
      it "returns true" do
        expect(subject.allow_redirect?).to be(true)
      end
    end

    context "when body is set" do
      before do
        subject.body = "OK"
      end

      it "returns false" do
        expect(subject.allow_redirect?).to be(false)
      end
    end

    context "when sending file" do
      before do
        subject.unsafe_send_file(__FILE__)
      end

      it "returns false" do
        expect(subject.renderable?).to be(false)
      end
    end
  end
end
