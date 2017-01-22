require 'test_helper'

describe Hanami::Action::Glue do

  describe "#renderable?" do
    describe "when sending file" do
      let(:action) { Glued::SendFile.new }

      it "isn't renderable while sending file" do
        action.call('REQUEST_METHOD' => 'GET')
        action.wont_be :renderable?
      end
    end
  end
end
