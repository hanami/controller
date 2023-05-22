RSpec.describe Hanami::Action::Rack::File do
  describe "#call" do
    it "doesn't mutate given env" do
      env      = Rack::MockRequest.env_for("/download", method: "GET")
      expected = env.dup

      file = described_class.new("/report.pdf", __dir__)
      file.call(env)

      expect(env).to eq(expected)
    end
  end
end
