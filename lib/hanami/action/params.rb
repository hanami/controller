# frozen_string_literal: true

require "hanami/validations/form"

module Hanami
  class Action
    # A set of params requested by the client
    #
    # It's able to extract the relevant params from a Rack env of from an Hash.
    #
    # There are three scenarios:
    #   * When used with Hanami::Router: it contains only the params from the request
    #   * When used standalone: it contains all the Rack env
    #   * Default: it returns the given hash as it is. It's useful for testing purposes.
    #
    # @since 0.1.0
    class Params < BaseParams
      include Hanami::Validations::Form
      include Hanami::Action::RequestParams::ActionValidations
      # This is a Hanami::Validations extension point
      #
      # @since 0.7.0
      # @api private
      def self._base_rules
        lambda do
          optional(:_csrf_token).filled(:str?)
        end
      end

      # Define params validations
      #
      # @param blk [Proc] the validations definitions
      #
      # @since 0.7.0
      #
      # @see https://guides.hanamirb.org/validations/overview
      #
      # @example
      #   class Signup < Hanami::Action
      #     MEGABYTE = 1024 ** 2
      #
      #     params do
      #       required(:first_name).filled(:str?)
      #       required(:last_name).filled(:str?)
      #       required(:email).filled?(:str?, format?: /\A.+@.+\z/)
      #       required(:password).filled(:str?).confirmation
      #       required(:terms_of_service).filled(:bool?)
      #       required(:age).filled(:int?, included_in?: 18..99)
      #       optional(:avatar).filled(size?: 1..(MEGABYTE * 3))
      #     end
      #
      #     def handle(req, *)
      #       halt 400 unless req.params.valid?
      #       # ...
      #     end
      #   end
      def self.params(&blk)
        validations(&blk || -> {})
      end
    end
  end
end
