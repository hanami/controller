# frozen_string_literal: true

require "rack/file"

module Hanami
  class Action
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
        # @since 1.0.0
        # @api private
        PATH_INFO = "PATH_INFO"

        # @param path [String,Pathname] file path
        #
        # @since 0.4.3
        # @api private
        def initialize(path, root)
          @file = ::Rack::File.new(root.to_s)
          @path = path.to_s
        end

        # @since 0.4.3
        # @api private
        def call(env)
          env = env.dup
          env[PATH_INFO] = @path

          @file.get(env)
        rescue Errno::ENOENT
          [404, {}, nil]
        end
      end
    end
  end
end
