require "hanami/action/application_configuration"

RSpec.describe Hanami::Action::ApplicationConfiguration, "default values" do
  subject(:configuration) { described_class.new }

  describe "sessions" do
    specify { expect(configuration.sessions).not_to be_enabled }
  end

  describe "name_inference_base" do
    specify { expect(configuration.name_inference_base).to eq "actions" }
  end

  describe "view_context_identifier" do
    specify { expect(configuration.view_context_identifier).to eq "view.context" }
  end

  describe "view_name_inferrer" do
    specify { expect(configuration.view_name_inferrer).to eq Hanami::Action::ViewNameInferrer }
  end

  describe "view_name_inference_base" do
    specify { expect(configuration.view_name_inference_base).to eq "views" }
  end

  describe "new default values applied to base action settings" do
    describe "default_request_format" do
      specify { expect(configuration.default_request_format).to eq :html }
    end

    describe "default_response_format" do
      specify { expect(configuration.default_response_format).to eq :html }
    end

    describe "default_headers" do
      specify {
        expect(configuration.default_headers).to eq(
          "X-Frame-Options" => "DENY",
          "X-Content-Type-Options" => "nosniff",
          "X-XSS-Protection" => "1; mode=block",
          "Content-Security-Policy" => "" \
            "base-uri 'self'; " \
            "child-src 'self'; " \
            "connect-src 'self'; " \
            "default-src 'none'; " \
            "font-src 'self'; " \
            "form-action 'self'; " \
            "frame-ancestors 'self'; " \
            "frame-src 'self'; " \
            "img-src 'self' https: data:; " \
            "media-src 'self'; " \
            "object-src 'none'; " \
            "plugin-types application/pdf; " \
            "script-src 'self'; " \
            "style-src 'self' 'unsafe-inline' https:"
        )
      }
    end
  end
end
