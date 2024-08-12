# frozen_string_literal: true

module Hanami
  class Action
    module RequestParams
      # Handles different ways to validate request params in an action, that come in from Hanami::Action::Validatable
      # It is supposed to handle all approaches through a common interface to access params/contract in the same way
      #
      # If you use params block or contract block, you can access the params/contract in the same way through
      # the request object
      # They will have the same methods available and all. Just keep in mind the differences between schema and contract
      # since 2.2.0
      # @api private
      module ActionValidations
        # Common errors for both params and contract validations
        #
        # @since 2.2.0
        class Errors < SimpleDelegator
          # @since 1.1.0
          # @api private
          def initialize(errors = {})
            super(errors.dup)
          end

          # Add an error to the param validations
          #
          # This has a semantic similar to `Hash#dig` where you use a set of keys
          # to get a nested value, here you use a set of keys to set a nested
          # value.
          #
          # @param args [Array<Symbol, String>] an array of arguments: the last
          #   one is the message to add (String), while the beginning of the array
          #   is made of keys to reach the attribute.
          #
          # @raise [ArgumentError] when try to add a message for a key that is
          #   already filled with incompatible message type.
          #   This usually happens with nested attributes: if you have a `:book`
          #   schema and the input doesn't include data for `:book`, the messages
          #   will be `["is missing"]`. In that case you can't add an error for a
          #   key nested under `:book`.
          #
          # @since 1.1.0
          #
          # @example Basic usage
          #   require "hanami/controller"
          #
          #   class MyAction < Hanami::Action
          #     params do
          #       required(:book).schema do
          #         required(:isbn).filled(:str?)
          #       end
          #     end
          #
          #     def handle(req, res)
          #       # 1. Don't try to save the record if the params aren't valid
          #       return unless req.params.valid?
          #
          #       BookRepository.new.create(req.params[:book])
          #     rescue Hanami::Model::UniqueConstraintViolationError
          #       # 2. Add an error in case the record wasn't unique
          #       req.params.errors.add(:book, :isbn, "is not unique")
          #     end
          #   end
          #
          # @example Invalid argument
          #   require "hanami/controller"
          #
          #   class MyAction < Hanami::Action
          #     params do
          #       required(:book).schema do
          #         required(:title).filled(:str?)
          #       end
          #     end
          #
          #     def handle(req, *)
          #       puts req.params.to_h   # => {}
          #       puts req.params.valid? # => false
          #       puts req.params.error_messages # => ["Book is missing"]
          #       puts req.params.errors         # => {:book=>["is missing"]}
          #
          #       req.params.errors.add(:book, :isbn, "is not unique") # => ArgumentError
          #     end
          #   end
          def add(*args)
            *keys, key, error = args
            _nested_attribute(keys, key) << error
          rescue TypeError
            raise ArgumentError.new("Can't add #{args.map(&:inspect).join(', ')} to #{inspect}")
          end

          private

          # @since 1.1.0
          # @api private
          def _nested_attribute(keys, key)
            if keys.empty?
              self
            else
              keys.inject(self) { |result, k| result[k] ||= {} }
              dig(*keys)
            end[key] ||= []
          end
        end

        # Initialize the params/contract and freeze.
        #
        # @param env [Hash] a Rack env or an hash of params.
        #
        # @return [Params]
        #
        # @since 2.2.0
        # @api private
        def initialize(env)
          @env = env
          @input = Hanami::Action::ParamsExtraction.new(env).call
          validation = validate
          @params = validation.to_h
          @errors = Errors.new(validation.messages)
          freeze
        end

        # Provide the same initialize method for both params and contract
        # since 2.2.0
        # @api private
        def self.included(klass)
          klass.send :prepend, ActionValidations
        end

        # Returns structured error messages
        #
        # @return [Hash]
        #
        # @since 2.2.0
        #
        # @example
        #   params.errors
        #     # => {
        #            :email=>["is missing", "is in invalid format"],
        #            :name=>["is missing"],
        #            :tos=>["is missing"],
        #            :age=>["is missing"],
        #            :address=>["is missing"]
        #          }
        attr_reader :errors

        # Returns flat collection of full error messages
        #
        # @return [Array]
        #
        # @since 2.2.0
        #
        # @example
        #   params.error_messages
        #     # => [
        #            "Email is missing",
        #            "Email is in invalid format",
        #            "Name is missing",
        #            "Tos is missing",
        #            "Age is missing",
        #            "Address is missing"
        #          ]
        def error_messages(error_set = errors)
          error_set.each_with_object([]) do |(key, messages), result|
            k = Utils::String.titleize(key)

            msgs = if messages.is_a?(::Hash)
                     error_messages(messages)
                   else
                     messages.map { |message| "#{k} #{message}" }
                   end

            result.concat(msgs)
          end
        end

        # Returns true if no validation errors are found,
        # false otherwise.
        #
        # @return [TrueClass, FalseClass]
        #
        # @since 2.2.0
        #
        # @example
        #   params.valid? # => true
        def valid?
          errors.empty?
        end

        # Pattern-matching support
        #
        # @return [::Hash]
        #
        # @since 2.2.0
        def deconstruct_keys(*)
          to_hash
        end
      end
    end
  end
end
