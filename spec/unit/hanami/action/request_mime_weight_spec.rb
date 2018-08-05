# frozen_string_literal: true

require "spec_helper"

RSpec.describe Hanami::Action::Mime::RequestMimeWeight do
  let(:plain_text) { described_class.new("text/plain", 0.7, 2) }
  let(:any_text) { described_class.new("text/*", 1, 0) }
  let(:anything) { described_class.new("*/*", 1, 3) }

  it "compares against another Specification" do
    expect(described_class.new("text/plain", 1, 2)).to be > plain_text
    expect(plain_text).to be > any_text
    expect(anything).to be < plain_text
    expect(described_class.new("text/*", 0.8, 0)).to be < any_text

    list = [plain_text, anything, any_text]
    expect(list.sort).to eq([anything, any_text, plain_text])
  end

  context "#priority" do
    it "returns a lower priority for media ranges" do
      expect(plain_text.priority).to eq(0.7)
      expect(any_text.priority).to eq(-9)
      expect(anything.priority).to eq(-19)
    end

    it "applies the quality of the mime type" do
      low_quality = described_class.new("text/plain", 0.2, 0)
      expect(low_quality.priority).to eq(0.2)

      high_quality_media_range = described_class.new("text/*", 0.8, 0)
      expect(high_quality_media_range.priority).to eq(-9.2)
    end
  end

  context "#<=>" do
    let(:html) { described_class.new("text/html", 1, 4) }
    let(:json) { described_class.new("application/json", 1, 1) }

    it "checks priority first" do
      expect(anything <=> json).to eq(-1)
      expect(any_text <=> anything).to eq(1)
    end

    it "against same priority and quality, a lower index takes precedence" do
      expect(html <=> json).to eq(-1)
    end
  end
end
