# frozen_string_literal: true

RSpec.describe Hanami::Action do
  describe "Path extension format detection" do
    class PathExtensionController
      class Index < Hanami::Action
        def handle(req, res)
          res.body = "format: #{res.format}"
        end
      end

      class JsonOnly < Hanami::Action
        config.format :json

        def handle(req, res)
          res.body = "format: #{res.format}"
        end
      end
    end

    let(:action) { PathExtensionController::Index.new }

    describe "when path has .json extension" do
      it "detects json format from path extension" do
        response = action.call("PATH_INFO" => "/users/123.json")

        expect(response.format).to eq(:json)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(response.body).to eq(["format: json"])
      end
    end

    describe "when path has .html extension" do
      it "detects html format from path extension" do
        response = action.call("PATH_INFO" => "/users/123.html")

        expect(response.format).to eq(:html)
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response.body).to eq(["format: html"])
      end
    end

    describe "when path has .xml extension" do
      it "detects xml format from path extension" do
        response = action.call("PATH_INFO" => "/users/123.xml")

        expect(response.format).to eq(:xml)
        expect(response.headers["Content-Type"]).to eq("application/xml; charset=utf-8")
        expect(response.body).to eq(["format: xml"])
      end
    end

    describe "when path has .csv extension" do
      it "detects csv format from path extension" do
        response = action.call("PATH_INFO" => "/users/123.csv")

        expect(response.format).to eq(:csv)
        expect(response.headers["Content-Type"]).to eq("text/csv; charset=utf-8")
        expect(response.body).to eq(["format: csv"])
      end
    end

    describe "when path has unknown extension" do
      it "falls back to default behavior" do
        response = action.call("PATH_INFO" => "/users/123.unknown")

        expect(response.format).to eq(:all)
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
        expect(response.body).to eq(["format: all"])
      end
    end

    describe "when path has no extension" do
      it "falls back to default behavior" do
        response = action.call("PATH_INFO" => "/users/123")

        expect(response.format).to eq(:all)
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
        expect(response.body).to eq(["format: all"])
      end
    end

    describe "when path has extension with query parameters" do
      it "detects format ignoring query parameters" do
        response = action.call("PATH_INFO" => "/users/123.json?page=1&limit=10")

        expect(response.format).to eq(:json)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(response.body).to eq(["format: json"])
      end
    end

    describe "when path has extension with fragment" do
      it "detects format ignoring fragment" do
        response = action.call("PATH_INFO" => "/users/123.json#section")

        expect(response.format).to eq(:json)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(response.body).to eq(["format: json"])
      end
    end

    describe "with configured formats" do
      let(:action) { PathExtensionController::JsonOnly.new }

      it "works with configured format restrictions" do
        response = action.call("PATH_INFO" => "/users/123.json")

        expect(response.format).to eq(:json)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
        expect(response.body).to eq(["format: json"])
      end

      it "still works when extension doesn't match configured format" do
        response = action.call("PATH_INFO" => "/users/123.html")

        expect(response.format).to eq(:html)
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response.body).to eq(["format: html"])
      end
    end

    describe "edge cases" do
      it "handles empty path" do
        response = action.call("PATH_INFO" => "")

        expect(response.format).to eq(:all)
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
      end

      it "handles root path" do
        response = action.call("PATH_INFO" => "/")

        expect(response.format).to eq(:all)
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
      end

      it "handles path with multiple dots" do
        response = action.call("PATH_INFO" => "/users/file.backup.json")

        expect(response.format).to eq(:json)
        expect(response.headers["Content-Type"]).to eq("application/json; charset=utf-8")
      end

      it "handles path ending with dot" do
        response = action.call("PATH_INFO" => "/users/123.")

        expect(response.format).to eq(:all)
        expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
      end
    end
  end
end
