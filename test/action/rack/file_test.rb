require 'test_helper'

describe Hanami::Action::Rack::File do
  describe "#call" do
    it "doesn't mutate given env" do
      env      = Rack::MockRequest.env_for("/download", method: "GET")
      expected = env.dup

      file = Hanami::Action::Rack::File.new("/report.pdf", __dir__)
      file.call(env)

      env.must_equal expected
    end
  end
end
