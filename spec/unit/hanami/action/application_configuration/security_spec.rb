# frozen_string_literal: true

require "hanami/action/application_configuration"

RSpec.describe Hanami::Action::ApplicationConfiguration, "#security" do
  let(:configuration) { described_class.new }
  subject(:security) { configuration.security }

  describe "settings" do
    describe "x_frame_options" do
      specify do
        expect(security.x_frame_options).to eq "DENY"
      end

      it "is included in headers" do
        expect(security.to_headers).to include("X-Frame-Options" => "DENY")
      end

      it "can be changed" do
        expect { security.x_frame_options = "SAMEORIGIN" }
          .to change { security.x_frame_options }
          .to("SAMEORIGIN")
      end
    end

    describe "x_content_type_options" do
      specify do
        expect(security.x_content_type_options).to eq "nosniff"
      end

      it "is included in headers" do
        expect(security.to_headers).to include("X-Content-Type-Options" => "nosniff")
      end

      it "can be changed" do
        expect { security.x_content_type_options = nil }
          .to change { security.x_content_type_options }
          .to(nil)
      end
    end

    describe "x_xss_protection" do
      specify do
        expect(security.x_xss_protection).to eq "1; mode=block"
      end

      it "is included in headers" do
        expect(security.to_headers).to include("X-XSS-Protection" => "1; mode=block")
      end

      it "can be changed" do
        expect { security.x_xss_protection = "1" }
          .to change { security.x_xss_protection }
          .to("1")
      end
    end

    describe "content_security_policy" do
      specify do
        expect(security.content_security_policy).to eq(
          form_action: "'self'",
          frame_ancestors: "'self'",
          base_uri: "'self'",
          default_src: "'none'",
          script_src: "'self'",
          connect_src: "'self'",
          img_src: "'self' https: data:",
          style_src: "'self' 'unsafe-inline' https:",
          font_src: "'self'",
          object_src: "'none'",
          plugin_types: "application/pdf",
          child_src: "'self'",
          frame_src: "'self'",
          media_src: "'self'"
        )
      end

      it "is included in headers" do
        expect(security.to_headers).to include(
          "Content-Security-Policy" => <<~TEXT.gsub("\n", " ").strip
            form-action 'self';
            frame-ancestors 'self';
            base-uri 'self';
            default-src 'none';
            script-src 'self';
            connect-src 'self';
            img-src 'self' https: data:;
            style-src 'self' 'unsafe-inline' https:;
            font-src 'self';
            object-src 'none';
            plugin-types application/pdf;
            child-src 'self';
            frame-src 'self';
            media-src 'self'
          TEXT
        )
      end

      it "does not include nil policy values in headers" do
        security.content_security_policy[:form_action] = nil
        expect(security.to_headers["Content-Security-Policy"]).not_to include("form-action")
      end

      it "can have a default directive changed" do
        expect { security.content_security_policy[:connect_src] = "'none'" }
          .to change { security.content_security_policy[:connect_src] }
          .to("'none'")
      end

      it "can have a new directive added" do
        expect { security.content_security_policy[:navigate_to] = "'self'" }
          .to change { security.content_security_policy[:navigate_to] }
          .to("'self'")
      end

      it "can be replaced" do
        expect { security.content_security_policy = {form_action: "'self'"} }
          .to change { security.content_security_policy }
          .to(form_action: "'self'")
      end
    end
  end

  describe "#to_headers" do
    subject(:headers) { security.to_headers }

    it "includes headers for all configurable settings" do
      expect(headers.keys).to eq(
        [
          "X-Frame-Options",
          "X-Content-Type-Options",
          "X-XSS-Protection",
          "Content-Security-Policy"
        ]
      )
    end

    it "removes headers for nil values" do
      security.x_frame_options = nil
      expect(headers.keys).not_to include("X-Frame-Options")
    end
  end
end
