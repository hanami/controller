# frozen_string_literal: true

require "rack"

RSpec.describe "Contracts" do
  describe "when defined as block in action" do
    let(:action) { ContractAction.new }

    context "when it has errors" do
      it "returns them" do
        response = action.call("birth_date" => "2000-01-01")

        expect(response.status).to eq 302
        expect(response.body).to eq ["{:errors=>{:book=>[\"is missing\"], :birth_date=>[\"you must be 18 years or older\"]}}"]
      end
    end

    context "when it is valid" do
      it "works" do
        response = action.call("birth_date" => Date.today - (365 * 15), "book" => {"title" => "Hanami"})

        expect(response.status).to eq 201
        expect(response.body).to eq ["{\"new_name\":\"HANAMI\"}"]
      end
    end
  end

  describe "#raw" do
    context "when this feature isn't enabled" do
      let(:action) { RawContractAction.new }

      it "raw gets all params" do
        File.open("spec/support/fixtures/multipart-upload.png", "rb") do |upload|
          response = action.call("id" => "1", "unknown" => "2", "upload" => upload)

          expect(response[:params][:id]).to eq("1")
          expect(response[:params][:unknown]).to eq("2")
          expect(FileUtils.cmp(response[:params][:upload], upload)).to be(true)

          expect(response[:params].raw.fetch("id")).to eq("1")
          expect(response[:params].raw.fetch("unknown")).to eq("2")
          expect(response[:params].raw.fetch("upload")).to eq(upload)
        end
      end
    end

    context "when this feature is enabled" do
      let(:action) { WhitelistedUploadDslContractAction.new }

      it "raw gets all params" do
        Tempfile.create("multipart-upload") do |upload|
          response = action.call("id" => "1", "unknown" => "2", "upload" => upload, "_csrf_token" => "3")

          expect(response[:params][:id]).to          eq(1)
          expect(response[:params][:unknown]).to     be(nil)
          expect(response[:params][:upload]).to      eq(upload)

          expect(response[:params].raw.fetch("id")).to          eq("1")
          expect(response[:params].raw.fetch("unknown")).to     eq("2")
          expect(response[:params].raw.fetch("upload")).to      eq(upload)
        end
      end
    end
  end
end
