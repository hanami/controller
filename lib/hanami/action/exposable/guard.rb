# frozen_string_literal: true

require "hanami/controller/error"

module Hanami
  module Controller
    # Exposure of reserved words
    #
    # @since 0.7.1
    class IllegalExposureError < Error
    end
  end

  module Action
    module Exposable
      # Guard for Exposures API.
      # Prevents exposure of reserved words
      #
      # @since 0.7.1
      # @api private
      #
      # @see Hanami::Action::Exposable::Guard::ClassMethods#expose
      # @see Hanami::Action::Exposable::Guard::ClassMethods#reserved_word?
      module Guard
        # Override Ruby's hook for modules.
        # It prepends a guard for the exposures logic
        #
        # @param base [Class] the target action
        #
        # @since 0.7.1
        # @api private
        #
        # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
        def self.included(base)
          class << base
            prepend ClassMethods
          end
        end

        # Exposures API Guard class methods
        #
        # @since 0.7.1
        # @api private
        module ClassMethods
          # Prevents exposure if names contain a reserved word.
          #
          # @param names [Array<Symbol>] the name(s) of the attribute(s) to be
          #   exposed
          #
          # @return [void]
          #
          # @since 0.7.1
          # @api private
          def expose(*names)
            detect_reserved_words!(names)

            super
          end

          private

          # Raises error if given names  contain a reserved word.
          #
          # @param names [Array<Symbol>] a list of names to be checked.
          #
          # @return [void]
          #
          # @raise [IllegalExposeError] if names contain one or more of reserved
          #   words
          #
          # @since 0.7.1
          # @api private
          def detect_reserved_words!(names)
            names.each do |name|
              if reserved_word?(name)
                raise Hanami::Controller::IllegalExposureError.new("#{name} is a reserved word. It cannot be exposed")
              end
            end
          end

          # Checks if a string is a reserved word
          #
          # Reserved word is a name of the method defined in one of the modules
          # of a given namespace.
          #
          # @param name [Symbol] the word to be checked
          # @param namespace [String] the namespace containing internal modules
          #
          # @return [true, false]
          #
          # @since 0.7.1
          # @api private
          def reserved_word?(name, namespace = "Hanami")
            if method_defined?(name) || private_method_defined?(name)
              method_owner = instance_method(name).owner

              Utils::String.namespace(method_owner) == namespace
            else
              false
            end
          end
        end
      end
    end
  end
end
