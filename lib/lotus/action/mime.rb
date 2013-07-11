module Lotus
  module Action
    module Mime

      protected
      def finish
        super
        headers.merge! 'Content-Type' => content_type
      end

      def content_type=(content_type)
        @content_type = content_type
      end

      def content_type
        @content_type || @_request.media_type || 'application/octet-stream'
      end
    end
  end
end
