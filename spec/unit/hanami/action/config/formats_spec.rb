# frozen_string_literal: true

RSpec.describe Hanami::Action::Config::Formats do
  subject(:formats) { described_class.new }

  describe "#mapping" do
    it "is a basic mapping of mime types to `:all` formats by default" do
      expect(formats.mapping).to eq(
        "application/octet-stream" => :all,
        "*/*" => :all
      )
    end

    it "can be replaced a mapping" do
      expect { formats.mapping = {all: "*/*"} }
        .to change { formats.mapping }
        .to("*/*" => :all)
    end
  end

  describe "#add" do
    it "adds a new mapping" do
      expect { formats.add(custom: "application/custom") }
        .to change { formats.mapping }
        .to include("application/custom" => :custom)
    end
  end

  describe "#values" do
    it "returns an empty array by default" do
      expect(formats.values).to eq []
    end

    it "can have a list of format names assigned" do
      expect { formats.values = [:json, :html] }
        .to change { formats.values }
        .to [:json, :html]
    end
  end

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

  describe "#mime_type_for" do
    before do
      formats.mapping = {html: "text/html"}
    end

    it "returns the configured MIME type for the given format" do
      expect(formats.mime_type_for(:html)).to eq "text/html"
    end

    it "returns nil if no matching MIME type is found" do
      expect(formats.mime_type_for(:missing)).to be nil
    end
  end
end
