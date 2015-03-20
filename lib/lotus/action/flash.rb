module Lotus
  module Action
    # Container useful to transport data with the HTTP session
    # It has a life span of one HTTP request or redirect.
    #
    # @since 0.3.0
    # @api private
    class Flash
      # Session key where the data is stored
      #
      # @since 0.3.0
      # @api private
      SESSION_KEY = :__flash

      # Session key where the last request_id is stored
      #
      # @since 0.4.0
      # @api private
      LAST_REQUEST_KEY = :__last_request_id

      # Initialize a new Flash instance
      #
      # @param session [Rack::Session::Abstract::SessionHash] the session
      # @param request_id [String] the HTTP Request ID
      #
      # @return [Lotus::Action::Flash] the flash
      #
      # @see http://www.rubydoc.info/gems/rack/Rack/Session/Abstract/SessionHash
      # @see Lotus::Action::Rack#session_id
      def initialize(session, request_id)
        @session         = session
        @request_id      = request_id
        @last_request_id = session[LAST_REQUEST_KEY]

        session[SESSION_KEY]             ||= {}
        session[SESSION_KEY][request_id] ||= {}
      end

      # Set the given value for the given key
      #
      # @param key [#to_s] the key
      # @param value [Object] the value
      #
      # @since 0.3.0
      # @api private
      def []=(key, value)
        data[key] = value
      end

      # Get the value associated to the given key, if any
      #
      # @return [Object,NilClass] the value
      #
      # @since 0.3.0
      # @api private
      def [](key)
        last_request_flash.merge(data).fetch(key) do
          _values.find {|data| !data[key].nil? }
        end
      end

      # Removes entirely the flash from the session if it has stale contents
      # or if empty.
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      def clear
        # FIXME we're just before a release and I can't find a proper way to reproduce
        # this bug that I've found via a browser.
        #
        # It may happen that `#flash` is nil, and those two methods will fail
        unless flash.nil?
          expire_stale!
          set_last_request_id!
          remove!
        end
      end

      # Check if there are contents stored in the flash from the current or the
      # previous request.
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.3.0
      # @api private
      def empty?
        _values.all?(&:empty?)
      end

      private

      # The flash registry that holds the data for **all** the recent requests
      #
      # @return [Hash] the flash
      #
      # @since 0.3.0
      # @api private
      def flash
        @session[SESSION_KEY] || {}
      end

      # The flash registry that holds the data **only for** the current request
      #
      # @return [Hash] the flash for the current request
      #
      # @since 0.3.0
      # @api private
      def data
        flash[@request_id] || {}
      end

      # Expire the stale data from the previous request.
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      def expire_stale!
        flash.each do |request_id, _|
          flash.delete(request_id) if delete?(request_id)
        end
      end

      # Remove the flash entirely from the session if empty.
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      #
      # @see Lotus::Action::Flash#empty?
      def remove!
        @session.delete(SESSION_KEY) if empty?
      end

      # Values from all the stored requests
      #
      # @return [Array]
      #
      # @since 0.3.0
      # @api private
      def _values
        flash.values
      end

      # Determine if delete data from flash for the given Request ID
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.4.0
      # @api private
      #
      # @see Lotus::Action::Flash#expire_stale!
      def delete?(request_id)
        ![@request_id, @session[LAST_REQUEST_KEY]].include?(request_id)
      end

      # Get the last request session flash
      #
      # @return [Hash] the flash of last request
      #
      # @since 0.4.0
      # @api private
      def last_request_flash
        flash[@last_request_id] || {}
      end

      # Store the last request_id to create the next flash with its values
      # is current flash is not empty.
      #
      # @return [void]
      # @since 0.4.0
      # @api private
      def set_last_request_id!
        @session[LAST_REQUEST_KEY] = @request_id if !empty?
      end

    end
  end
end
