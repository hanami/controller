module Lotus
  module Action
    # Container useful to transport data with the HTTP session
    # It has a life span of one HTTP request or redirect.
    #
    # @since x.x.x
    # @api private
    class Flash
      # Session key where the data is stored
      #
      # @since x.x.x
      # @api private
      SESSION_KEY = :__flash

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
        @session    = session
        @request_id = request_id

        session[SESSION_KEY]             ||= {}
        session[SESSION_KEY][request_id] ||= {}
      end

      # Set the given value for the given key
      #
      # @param key [#to_s] the key
      # @param value [Object] the value
      #
      # @since x.x.x
      # @api private
      def []=(key, value)
        data[key] = value
      end

      # Get the value associated to the given key, if any
      #
      # @return [Object,NilClass] the value
      #
      # @since x.x.x
      # @api private
      def [](key)
        data.fetch(key) do
          _values.find {|data| !data[key].nil? }
        end
      end

      # Removes entirely the flash from the session if it has stale contents
      # or if empty.
      #
      # @return [void]
      #
      # @since x.x.x
      # @api private
      def clear
        expire_stale!
        remove!
      end

      # Check if there are contents stored in the flash from the current or the
      # previous request.
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since x.x.x
      # @api private
      def empty?
        _values.all?(&:empty?)
      end

      private

      # The flash registry that holds the data for **all** the recent requests
      #
      # @return [Hash] the flash
      #
      # @since x.x.x
      # @api private
      def flash
        @session[SESSION_KEY]
      end

      # The flash registry that holds the data **only for** the current request
      #
      # @return [Hash] the flash for the current request
      #
      # @since x.x.x
      # @api private
      def data
        flash[@request_id]
      end

      # Expire the stale data from the previous request.
      #
      # @return [void]
      #
      # @since x.x.x
      # @api private
      def expire_stale!
        flash.each do |request_id, _|
          flash.delete(request_id) if @request_id != request_id
        end
      end

      # Remove the flash entirely from the session if empty.
      #
      # @return [void]
      #
      # @since x.x.x
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
      # @since x.x.x
      # @api private
      def _values
        flash.values
      end
    end
  end
end
