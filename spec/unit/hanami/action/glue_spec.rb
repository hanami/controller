# frozen_string_literal: true

RSpec.describe Hanami::Action::Glue do
  describe "#renderable?" do
    describe "when sending file" do
      let(:action) { Glued::SendFile.new }

      it "isn't renderable while sending file" do
        action.call("REQUEST_METHOD" => "GET")
        expect(action).to_not be_renderable
      end
    end
  end
end
