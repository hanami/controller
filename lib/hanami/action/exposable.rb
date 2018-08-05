# frozen_string_literal: true

require "hanami/action/exposable/guard"

module Hanami
  module Action
    # Exposures API
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Exposable::ClassMethods#expose
    module Exposable
      # Override Ruby's hook for modules.
      # It includes exposures logic
      #
      # @param base [Class] the target action
      #
      # @since 0.1.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
      def self.included(base)
        base.class_eval do
          extend ClassMethods
          include Guard

          _expose :params
        end
      end

      # Exposures API class methods
      #
      # @since 0.1.0
      # @api private
      module ClassMethods
        # Expose the given attributes on the outside of the object with
        # a getter and a special method called #exposures.
        #
        # @param names [Array<Symbol>] the name(s) of the attribute(s) to be
        #   exposed
        #
        # @return [void]
        #
        # @since 0.1.0
        #
        # @example
        #   require 'hanami/controller'
        #
        #   class Show
        #     include Hanami::Action
        #
        #     expose :article, :tags
        #
        #     def call(params)
        #       @article = Article.find params[:id]
        #       @tags    = Tag.for(article)
        #     end
        #   end
        #
        #   action = Show.new
        #   action.call({id: 23})
        #
        #   action.article # => #<Article ...>
        #   action.tags    # => [#<Tag ...>, #<Tag ...>]
        #
        #   action.exposures # => { :article => #<Article ...>, :tags => [ ... ] }
        def expose(*names)
          class_eval do
            names.each do |name|
              attr_reader(name) unless attr_reader?(name)
            end

            exposures.push(*names)
          end
        end

        # Alias of #expose to be used in internal modules.
        # #_expose is not watched by the Guard
        alias _expose expose

        # Set of exposures attribute names
        #
        # @return [Array] the exposures attribute names
        #
        # @since 0.1.0
        # @api private
        def exposures
          @exposures ||= []
        end

        private

        # Check if the attr_reader is already defined
        #
        # @since 0.3.0
        # @api private
        def attr_reader?(name)
          (instance_methods | private_instance_methods).include?(name)
        end
      end

      # Set of exposures
      #
      # @return [Hash] the exposures
      #
      # @since 0.1.0
      #
      # @see Hanami::Action::Exposable::ClassMethods.expose
      def exposures
        @exposures ||= {}.tap do |result|
          self.class.exposures.each do |name|
            result[name] = send(name)
          end
        end
      end

      # Finalize the response
      #
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Action#finish
      def finish
        super
        exposures
      end
    end
  end
end
