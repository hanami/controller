module Lotus
  module Action
    # A request model build on top of Rack::Request, that guarantees backwards
    # compatibility within minor versions of lotus/controller
    #
    # Since x.x.x
    class Request < ::Rack::Request

      def content_type
        raise NotImplementedError, 'Please use Action#content_type'
      end

      def session
        raise NotImplementedError, 'Please include Action::Session and use Action#session'
      end

      def cookies
        raise NotImplementedError, 'Please include Action::Cookies and use Action#cookies'
      end

      def params
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      def update_param(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      def delete_param(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      def [](*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      def []=(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      def values_at(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end
    end
  end
end
