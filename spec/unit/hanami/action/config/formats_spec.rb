# frozen_string_literal: true

RSpec.xdescribe Hanami::Action::Config::Formats do
  subject(:formats) { described_class.new }

  describe "#register" do
    it "registers a mapping" do
      expect { formats.register(:custom, media_type: "application/custom") }
        .to change { formats.mapping }
        .to include(custom: have_attributes(media_type: "application/custom"))
    end

    it "registers a mapping with content types" do
      expect {
        formats.register(
          :jsonapi,
          media_type: "application/vnd.api+json",
          content_types: ["application/vnd.api+json", "application/json"]
        )
      }
        .to change { formats.mapping }
        .to include(
          jsonapi: have_attributes(
            media_type: "application/vnd.api+json",
            content_types: ["application/vnd.api+json", "application/json"]
          )
        )
    end
  end

  describe "#accepted" do
    it "returns an empty array by default" do
      expect(formats.accepted).to eq []
    end

    it "returns the formats configured by #accept" do
      expect { formats.accept :json }
        .to change { formats.accepted }
        .to [:json]
    end

    it "can be assigned with an array of formats" do
      expect { formats.accepted = [:json, :html] }
        .to change { formats.accepted }
        .to [:json, :html]
    end
  end

  describe "#accept" do
    it "sets the list of accepted formats" do
      expect { formats.accept :json, :html }
        .to change { formats.accepted }
        .to [:json, :html]
    end

    it "appends to the list of accepted formats when called more than once" do
      expect { formats.accept :json }
        .to change { formats.accepted }
        .to([:json])

      expect { formats.accept :html }
        .to change { formats.accepted }
        .to([:json, :html])

      expect { formats.accept :json, :custom }
        .to change { formats.accepted }
        .to [:json, :html, :custom]
    end

    it "sets the default format to the first format, when no default is set" do
      expect { formats.accept :json }
        .to change { formats.default }
        .to :json
    end

    it "does not change the default format when it has already been set" do
      formats.default = :html

      expect { formats.accept :json }
        .not_to change { formats.default }
        .from :html
    end
  end

  describe "#default" do
    it "returns nil by default" do
      expect(formats.default).to be nil
    end

    it "can be assigned to a format" do
      expect { formats.default = :json }
        .to change { formats.default }
        .to :json
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
      formats.register(:html, media_type: "text/html")
    end

    it "returns the configured format for the given MIME type" do
      expect(formats.format_for("text/html")).to eq :html
    end

    it "returns the most recently configured format for a given MIME type" do
      formats.register :htm, media_type: "text/html"

      expect(formats.format_for("text/html")).to eq(:htm)
    end

    it "returns nil if no matching format is found" do
      expect(formats.format_for("*/*")).to be nil
    end
  end

  describe "#media_type_for" do
    before do
      formats.register(:custom, media_type: "application/custom")
    end

    it "returns the configured media type for the given format" do
      expect(formats.media_type_for(:custom)).to eq "application/custom"
    end

    it "returns nil if no matching format is found" do
      expect(formats.mime_type_for(:missing)).to be nil
    end
  end

  describe "deprecated behavior" do
    describe "#add" do
      it "adds a new mapping" do
        expect { formats.add(:custom, "application/custom") }
          .to change { formats.mapping }
          .to include(custom: have_attributes(media_type: "application/custom"))
      end

      it "replaces a previously set mapping for a given MIME type" do
        formats.register(:html, media_type: "text/html")
        formats.add :custom, "text/html"

        expect(formats.mapping).to match(custom: have_attributes(media_type: "text/html"))
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
  end
end
