module Lotus
  module Action
    # Manages HTTP headers and body
    module Http

      # Ensures that there's no Content-Type if the response code requires
      # no body
      def finish
        super
        if requires_no_body?
          headers.delete(Mime::CONTENT_TYPE)
        end
      end

    end
  end
end
