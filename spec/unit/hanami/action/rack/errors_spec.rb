# frozen_string_literal: true

RSpec.describe Hanami::Action::Rack::Errors do
  describe ".set" do
    let(:exception) do
      exception = StandardError.new("Exception")
      exception.set_backtrace(["backtrace/path/1", "backtrace/path/2"])
      exception
    end

    let(:env) { { "rack.errors" => StringIO.new } }

    it "writes exception info to rack.errors" do
      described_class.set(env, exception)
      expect(env["rack.errors"].string).to eq("StandardError: Exception\n\tbacktrace/path/1\n\tbacktrace/path/2")
    end

    it "stores exception info in rack.exception" do
      described_class.set(env, exception)
      expect(env["rack.exception"]).to eq(exception)
    end
  end
end
