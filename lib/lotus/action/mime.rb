module Lotus
  module Action
    module Mime
      CONTENT_TYPE         = 'Content-Type'.freeze
      DEFAULT_CONTENT_TYPE = 'application/octet-stream'.freeze

      protected
      def finish
        super
        headers.merge! CONTENT_TYPE => content_type
      end

      def content_type=(content_type)
        @content_type = content_type
      end

      def content_type
        @content_type || @_request.media_type || @_request.accepts || DEFAULT_CONTENT_TYPE
      end
    end
  end
end
