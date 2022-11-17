# frozen_string_literal: true

RSpec.describe Hanami::Action::Config::Formats do
  subject(:formats) { described_class.new }

  describe "#format_for" do
    before do
      formats.mapping = {html: "text/html"}
    end

    it "returns the configured format for the given MIME type" do
      expect(formats.format_for("text/html")).to eq :html
    end

    it "returns the most recently configured format for a given MIME type" do
      formats.add htm: "text/html"

      expect(formats.format_for("text/html")).to eq(:htm)
    end

    it "returns nil if no matching format is found" do
      expect(formats.format_for("*/*")).to be nil
    end
  end
end
