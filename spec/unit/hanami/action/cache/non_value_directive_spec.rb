RSpec.describe Hanami::Action::Cache::NonValueDirective do
  describe "#to_str" do
    it "returns as http cache format" do
      subject = described_class.new(:no_cache)
      expect(subject.to_str).to eq("no-cache")
    end
  end
end
