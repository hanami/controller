# frozen_string_literal: true

module Hanami
  class Action
    # Checks for blank
    #
    # @since 2.0.0
    # @api private
    class Blank
      # Matcher for blank strings
      #
      # @since 2.0.0
      # @api private
      STRING_MATCHER = /\A[[:space:]]*\z/

      # Checks if object is blank
      #
      # @example Basic Usage
      #   require "hanami/action/blank"
      #
      #   Hanami::Action::Blank.blank?("")   # => true
      #   Hanami::Action::Blank.blank?("  ") # => true
      #   Hanami::Action::Blank.blank?(nil)  # => true
      #   Hanami::Action::Blank.blank?(true) # => false
      #   Hanami::Action::Blank.blank?(1)    # => false
      #
      # @param object the argument
      #
      # @return [TrueClass,FalseClass] info, whether object is blank
      #
      # @since 2.0.0
      # @api private
      def self.blank?(object)
        case object
        when ::String
          STRING_MATCHER === object
        when ::Hash, ::Array
          object.empty?
        when TrueClass, Numeric
          false
        when FalseClass, NilClass
          true
        else
          object.respond_to?(:empty?) ? object.empty? : !self
        end
      end
    end
  end
end
