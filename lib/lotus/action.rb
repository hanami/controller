require 'lotus/action/rack'
require 'lotus/action/mime'
require 'lotus/action/redirect'
require 'lotus/action/cookies'
require 'lotus/action/exposable'
require 'lotus/action/throwable'
require 'lotus/action/callbacks'
require 'lotus/action/callable'

module Lotus
  module Action
    def self.included(base)
      base.class_eval do
        include Rack
        include Mime
        include Redirect
        include Cookies
        include Exposable
        include Throwable
        include Callbacks
        prepend Callable
      end
    end

    protected

    def finish
    end
  end
end
