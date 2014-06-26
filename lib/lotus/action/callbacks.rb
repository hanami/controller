require 'lotus/utils/class_attribute'
require 'lotus/utils/callbacks'

module Lotus
  module Action
    # Before and after callbacks
    #
    # @since 0.1.0
    # @see Lotus::Action::ClassMethods#before
    # @see Lotus::Action::ClassMethods#after
    module Callbacks
      # Override Ruby's hook for modules.
      # It includes callbacks logic
      #
      # @param base [Class] the target action
      #
      # @since 0.1.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
      def self.included(base)
        base.class_eval do
          extend  ClassMethods
          prepend InstanceMethods
        end
      end

      module ClassMethods
        # Override Ruby's hook for modules.
        # It includes callbacks logic
        #
        # @param base [Class] the target action
        #
        # @since 0.1.0
        # @api private
        #
        # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-extended
        def self.extended(base)
          base.class_eval do
            include Utils::ClassAttribute

            class_attribute :before_callbacks
            self.before_callbacks = Utils::Callbacks::Chain.new

            class_attribute :after_callbacks
            self.after_callbacks = Utils::Callbacks::Chain.new
          end
        end

        # Define a callback for an Action.
        # The callback will be executed **before** the action is called, in the
        # order they are added.
        #
        # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
        #   each of them is representing a name of a method available in the
        #   context of the Action.
        #
        # @param blk [Proc] an anonymous function to be executed
        #
        # @return [void]
        #
        # @since 0.1.0
        #
        # @example Method names (symbols)
        #   require 'lotus/controller'
        #
        #   class Show
        #     include Lotus::Action
        #
        #     before :authenticate, :set_article
        #
        #     def call(params)
        #     end
        #
        #     private
        #     def authenticate
        #       # ...
        #     end
        #
        #     # `params` in the method signature is optional
        #     def set_article(params)
        #       @article = Article.find params[:id]
        #     end
        #   end
        #
        #   # The order of execution will be:
        #   #
        #   # 1. #authenticate
        #   # 2. #set_article
        #   # 3. #call
        #
        # @example Anonymous functions (Procs)
        #   require 'lotus/controller'
        #
        #   class Show
        #     include Lotus::Action
        #
        #     before { ... } # 1 do some authentication stuff
        #     before {|params| @article = Article.find params[:id] } # 2
        #
        #     def call(params)
        #     end
        #   end
        #
        #   # The order of execution will be:
        #   #
        #   # 1. authentication
        #   # 2. set the article
        #   # 3. #call
        def before(*callbacks, &blk)
          before_callbacks.add(*callbacks, &blk)
        end

        # Define a callback for an Action.
        # The callback will be executed **after** the action is called, in the
        # order they are added.
        #
        # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
        #   each of them is representing a name of a method available in the
        #   context of the Action.
        #
        # @param blk [Proc] an anonymous function to be executed
        #
        # @return [void]
        #
        # @since 0.1.0
        #
        # @see Lotus::Action::Callbacks::ClassMethods#before
        def after(*callbacks, &blk)
          after_callbacks.add(*callbacks, &blk)
        end
      end

      module InstanceMethods
        # Implements the Rack/Lotus::Action protocol
        #
        # @since 0.1.0
        # @api private
        def call(params)
          _run_before_callbacks(params)
          super if defined?(super)
          _run_after_callbacks(params)
        end

        private
        def _run_before_callbacks(params)
          self.class.before_callbacks.run(self, params)
        end

        def _run_after_callbacks(params)
          self.class.after_callbacks.run(self, params)
        end
      end
    end
  end
end
