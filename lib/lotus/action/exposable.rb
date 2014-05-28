module Lotus
  module Action
    # Exposures API
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Exposable::ClassMethods#expose
    module Exposable
      def self.included(base)
        base.extend ClassMethods
      end

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
        #   require 'lotus/controller'
        #
        #   class Show
        #     include Lotus::Action
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
            attr_reader(   *names)
            exposures.push(*names)
          end
        end

        # Set of exposures attribute names
        #
        # @return [Array] the exposures attribute names
        #
        # @since 0.1.0
        # @api private
        def exposures
          @exposures ||= []
        end
      end

      # Set of exposures
      #
      # @return [Hash] the exposures
      #
      # @since 0.1.0
      #
      # @see Lotus::Action::Exposable::ClassMethods.expose
      def exposures
        {}.tap do |result|
          self.class.exposures.each do |exposure|
            result[exposure] = send(exposure)
          end
        end
      end
    end
  end
end
