RSpec.describe Hanami::Controller do
  describe ".configuration" do
    it "exposes class configuration" do
      expect(Hanami::Controller.configuration).to be_kind_of(Hanami::Controller::Configuration)
    end
  end
end
