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
      expect { formats.add(:custom, "application/custom") }
        .to change { formats.mapping }
        .to include("application/custom" => :custom)
    end

    it "can add a mapping to multiple content types" do
      expect { formats.add(:json, ["application/json", "application/json+scim"]) }
        .to change { formats.mapping }
        .to include("application/json" => :json, "application/json+scim" => :json)
    end

    it "replaces the a previously set mapping for a given MIME type" do
      formats.mapping = {html: "text/html"}
      formats.add :custom, "text/html"

      expect(formats.mapping).to eq("text/html" => :custom)
    end

    it "appends the format to the list of enabled formats" do
      formats.values = [:json]

      expect {
        formats.add(:custom, "application/custom")
        formats.add(:custom, "application/custom+more")
      }
        .to change { formats.values }
        .to [:json, :custom]
    end

    it "raises an error if the given format cannot be coerced into symbol" do
      expect { formats.add(23, "boom") }.to raise_error(TypeError)
    end

    it "raises an error if the given mime type cannot be coerced into string" do
      obj = Class.new(BasicObject) do
        def hash
          23
        end
      end.new

      expect { formats.add(:boom, obj) }.to raise_error(TypeError)
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

  describe "#clear" do
    it "clears any previously assigned mappings and values" do
      formats.add(:custom, "application/custom")
      formats.values = [:custom]

      formats.clear

      expect(formats.mapping.keys).not_to include "application/custom"
      expect(formats.values).to eq []
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
      formats.add :htm, "text/html"

      expect(formats.format_for("text/html")).to eq(:htm)
    end

    it "returns nil if no matching format is found" do
      expect(formats.format_for("*/*")).to be nil
    end
  end

  describe "#mime_type_for" do
    before do
      formats.mapping = {html: ["text/html", "text/htm"]}
    end

    it "returns the first configured MIME type for the given format" do
      expect(formats.mime_type_for(:html)).to eq "text/html"
    end

    it "returns nil if no matching MIME type is found" do
      expect(formats.mime_type_for(:missing)).to be nil
    end
  end

  describe "#mime_types_for" do
    before do
      formats.mapping = {html: ["text/html", "text/htm"]}
    end

    it "returns all configured MIME types for the given format" do
      expect(formats.mime_types_for(:html)).to eq ["text/html", "text/htm"]
    end

    it "returns an empty array if no matching MIME type is found" do
      expect(formats.mime_types_for(:missing)).to eq []
    end
  end
end
