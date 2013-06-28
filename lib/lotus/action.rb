require 'lotus/action/exposable'
require 'lotus/action/callbacks'
require 'lotus/action/callable'

module Lotus
  module Action
    def self.included(base)
      base.class_eval do
        include Exposable
        include Callbacks
        prepend Callable
      end
    end
  end
end
