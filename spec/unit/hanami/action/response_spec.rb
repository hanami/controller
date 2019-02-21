# frozen_string_literal: true

RSpec.describe Hanami::Action::Response do
  describe "#renderable?" do
    subject { described_class.new(action: "action", configuration: Hanami::Controller::Configuration.new, env: env) }
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
end
