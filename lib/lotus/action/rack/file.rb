require 'rack/file'

module Lotus
  module Action
    module Rack
      # File to be sent
      #
      # @since x.x.x
      # @api private
      #
      # @see Lotus::Action::Rack#send_file
      class File
        # @param path [String,Pathname] file path
        #
        # @since x.x.x
        # @api private
        def initialize(path)
          @file = ::Rack::File.new(nil)
          @path = path
        end

        # @since x.x.x
        # @api private
        def call(env)
          @file.path = @path.to_s
          @file.serving(env)
        rescue Errno::ENOENT
          [404, {}, nil]
        end
      end
    end
  end
end
