module Hanami
  class Action
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

      # Session key where keep data is store for redirect
      #
      # @since x.x.x
      # @api private
      KEPT_KEY = :__kept_key

      # Initialize a new Flash instance
      #
      # @param session [Rack::Session::Abstract::SessionHash] the session
      #
      # @return [Hanami::Action::Flash] the flash
      #
      # @see http://www.rubydoc.info/gems/rack/Rack/Session/Abstract/SessionHash
      # @see Hanami::Action::Rack#session_id
      def initialize(session)
        @session         = session
        @keep            = false

        session[KEPT_KEY] ||= []
        session[SESSION_KEY] = {}
      end

      # Set the given value for the given key
      #
      # @param key [#to_s] the key
      # @param value [Object] the value
      #
      # @since 0.3.0
      # @api private
      def []=(key, value)
        _data[key] = value
      end

      # Get the value associated to the given key, if any
      #
      # @return [Object,NilClass] the value
      #
      # @since 0.3.0
      # @api private
      def [](key)
        _data.fetch(key) { search_in_kept_data(key) }
      end

      # Iterates through current request data and kept data
      #
      # @param blk [Proc]
      #
      # @since 1.2.0
      def each(&blk)
        _values.each(&blk)
      end

      # Iterates through current request data and kept data
      #
      # @param blk [Proc]
      # @return [Array]
      #
      # @since 1.2.0
      def map(&blk)
        _values.map(&blk)
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
        unless _data.nil?
          update_kept_request_count
          keep_data if @keep
          expire_kept
          remove
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
        _values.empty?
      end

      # @return [String]
      #
      # @since 1.0.0
      def inspect
        "#<#{self.class}:#{'0x%x' % (__id__ << 1)} {:data=>#{_data.inspect}, :kept=>#{kept_data.inspect}} >"
      end

      # Set @keep to true, is use when triggering a redirect, and the content of _data is not empty.
      # @return [TrueClass, NilClass]
      #
      # @since x.x.x
      # @api private
      #
      # @see Hanami::Action::Flash#empty?
      def keep!
        return if empty?
        @keep = true
      end

      private

      # The flash registry that holds the data for the current requests
      #
      # @return [Hash] the flash
      #
      # @since 0.3.0
      # @api private
      def _data
        @session[SESSION_KEY] || {}
      end

      # Remove the flash entirely from the session if empty.
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Action::Flash#empty?
      def remove
        if empty?
          @session.delete(SESSION_KEY)
          @session.delete(KEPT_KEY)
        end
      end

      # Returns the values from current session and kept.
      #
      # @return [Hash]
      #
      # @since 0.3.0
      # @api private
      def _values
        _data.merge(kept_data)
      end

      # Get the kept request data
      #
      # @return [Array]
      #
      # @since x.x.x
      # @api private
      def kept
        @session[KEPT_KEY] || []
      end

      # Merge current data into KEPT_KEY hash
      #
      # @return [Hash] the current value of KEPT_KEY
      #
      # @since x.x.x
      # @api private
      def keep_data
        new_kept_data = kept << JSON.generate({ count: 0, data: _data })

        update_kept(new_kept_data)
      end

      # Removes from kept data those who have lived for more than two requests
      #
      # @return [Hash] the current value of KEPT_KEY
      #
      # @since x.x.x
      # @api private
      def expire_kept
        new_kept_data = kept.reject do |kept_data|
          parsed = JSON.parse(kept_data)
          parsed['count'] >= 2 if is_hash?(parsed) && parsed['count'].is_a?(Integer)
        end

        update_kept(new_kept_data)
      end

      # Update the count of request for each kept data
      #
      # @return [Hash] the current value of KEPT_KEY
      #
      # @since x.x.x
      # @api private
      def update_kept_request_count
        new_kept_data = kept.map do |kept_data|
          parsed = JSON.parse(kept_data)
          parsed['count'] += 1 if is_hash?(parsed) && parsed['count'].is_a?(Integer)
          JSON.generate(parsed)
        end

        update_kept(new_kept_data)
      end

      # Search in the kept data for a match on the key
      #
      # @param key [#to_s] the key
      # @return [Object, NilClass]
      #
      # @since x.x.x
      # @api private
      def search_in_kept_data(key)
        string_key = key.to_s

        data = kept.find do |kept_data|
          parsed = JSON.parse(kept_data)
          parsed['data'].fetch(string_key, nil) if is_hash?(parsed['data'])
        end

        JSON.parse(data)['data'][string_key] if data
      end

      # Set the given new_kept_data to KEPT_KEY
      #
      # @param new_kept_data
      # @return [Hash] the current value of KEPT_KEY
      #
      # @since x.x.x
      # @api private
      def update_kept(new_kept_data)
        @session[KEPT_KEY] = new_kept_data
      end

      # Values from kept
      #
      # @return [Hash]
      #
      # @since x.x.x
      # @api private
      def kept_data
        kept.each_with_object({}) { |kept_data, result| result.merge!(JSON.parse(kept_data)['data']) }
      end

      # Check if data is a hash
      #
      # @param new_kept_data
      # @return [TrueClass, FalseClass]
      #
      # @since x.x.x
      # @api private
      def is_hash?(data)
        data && data.is_a?(Hash)
      end
    end
  end
end
