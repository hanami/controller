RSpec.describe Hanami::Action::Glue do
  describe "#renderable?" do
    describe "when sending file" do
      let(:action) { Glued::SendFile.new(configuration: configuration) }
      let(:configuration) do
        Hanami::Controller::Configuration.new do |config|
          config.public_directory = "spec/support/fixtures"
        end
      end

      it "isn't renderable while sending file" do
        action.call('REQUEST_METHOD' => 'GET')
        expect(action).to_not be_renderable
      end
    end
  end
end
