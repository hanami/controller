require 'lotus/action'
require 'lotus/controller/dsl'

module Lotus
  module Controller
    VERSION = '0.0.1'

    def self.included(base)
      base.class_eval do
        include Dsl
      end
    end
  end
end

