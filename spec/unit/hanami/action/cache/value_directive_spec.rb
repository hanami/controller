# frozen_string_literal: true

RSpec.describe Hanami::Action::Cache::ValueDirective do
  describe "#to_str" do
    it "returns as http cache format" do
      subject = described_class.new(:max_age, 600)
      expect(subject.to_str).to eq("max-age=600")
    end
  end
end
