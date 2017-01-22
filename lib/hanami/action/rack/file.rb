require 'rack/file'

module Hanami
  module Action
    module Rack
      # File to be sent
      #
      # @since 0.4.3
      # @api private
      #
      # @see Hanami::Action::Rack#send_file
      class File

        # The key that returns path info from the Rack env
        #
        # @since x.x.x
        # @api private
        PATH_INFO = "PATH_INFO".freeze

        # @param path [String,Pathname] file path
        #
        # @since 0.4.3
        # @api private
        def initialize(path, root)
          @file = ::Rack::File.new(root)
          @path = path
        end

        # @since 0.4.3
        # @api private
        def call(env)
          env[PATH_INFO] = @path
          @file.get(env)
        rescue Errno::ENOENT
          [404, {}, nil]
        end
      end
    end
  end
end
