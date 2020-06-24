begin
  require 'hanami/validations'
  require 'hanami/action/validatable'
rescue LoadError
end

require 'hanami/utils/class_attribute'
require 'hanami/utils/callbacks'
require 'hanami/utils'
require 'hanami/utils/string'
require 'hanami/utils/kernel'
require 'rack/utils'

require_relative 'base_params'
require_relative 'configuration'
require_relative 'halt'
require_relative 'mime'
require_relative 'rack/file'
require_relative 'request'
require_relative 'response'

module Hanami
  class Action
    module StandaloneAction
      def self.included(klass)
        klass.include InstanceMethods
        klass.extend ClassMethods
      end

      module ClassMethods
        def configuration
          @configuration ||= Configuration.new
        end

        alias config configuration

        # Override Ruby's hook for modules.
        # It includes basic Hanami::Action modules to the given class.
        #
        # @param subclass [Class] the target action
        #
        # @since 0.1.0
        # @api private
        def inherited(subclass)
          if subclass.superclass == Action
            subclass.class_eval do
              include Utils::ClassAttribute

              class_attribute :before_callbacks
              self.before_callbacks = Utils::Callbacks::Chain.new

              class_attribute :after_callbacks
              self.after_callbacks = Utils::Callbacks::Chain.new

              include Validatable if defined?(Validatable)
            end
          end

          subclass.instance_variable_set '@configuration', configuration.dup
        end

        # Returns the class which defines the params
        #
        # Returns the class which has been provided to define the
        # params. By default this will be Hanami::Action::Params.
        #
        # @return [Class] A params class (when whitelisted) or
        #   Hanami::Action::Params
        #
        # @api private
        # @since 0.7.0
        def params_class
          @params_class ||= BaseParams
        end

        # FIXME: make this thread-safe
        def accepted_formats
          @accepted_formats ||= []
        end

        # FIXME: make this thread-safe
        def handled_exceptions
          @handled_exceptions ||= {}
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
        # @since 0.3.2
        #
        # @see Hanami::Action::Callbacks::ClassMethods#append_after
        #
        # @example Method names (symbols)
        #   require 'hanami/controller'
        #
        #   class Show
        #     include Hanami::Action
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
        #   require 'hanami/controller'
        #
        #   class Show
        #     include Hanami::Action
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
        def append_before(*callbacks, &blk)
          before_callbacks.append(*callbacks, &blk)
        end

        alias_method :before, :append_before

        # class << self
        #   # @since 0.1.0
        #   alias before append_before
        # end

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
        # @since 0.3.2
        #
        # @see Hanami::Action::Callbacks::ClassMethods#append_before
        def append_after(*callbacks, &blk)
          after_callbacks.append(*callbacks, &blk)
        end

        alias_method :after, :append_after

        # class << self
        #   # @since 0.1.0
        #   alias after append_after
        # end

        # Define a callback for an Action.
        # The callback will be executed **before** the action is called.
        # It will add the callback at the beginning of the callbacks' chain.
        #
        # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
        #   each of them is representing a name of a method available in the
        #   context of the Action.
        #
        # @param blk [Proc] an anonymous function to be executed
        #
        # @return [void]
        #
        # @since 0.3.2
        #
        # @see Hanami::Action::Callbacks::ClassMethods#prepend_after
        def prepend_before(*callbacks, &blk)
          before_callbacks.prepend(*callbacks, &blk)
        end

        # Define a callback for an Action.
        # The callback will be executed **after** the action is called.
        # It will add the callback at the beginning of the callbacks' chain.
        #
        # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
        #   each of them is representing a name of a method available in the
        #   context of the Action.
        #
        # @param blk [Proc] an anonymous function to be executed
        #
        # @return [void]
        #
        # @since 0.3.2
        #
        # @see Hanami::Action::Callbacks::ClassMethods#prepend_before
        def prepend_after(*callbacks, &blk)
          after_callbacks.prepend(*callbacks, &blk)
        end

        # Restrict the access to the specified mime type symbols.
        #
        # @param formats[Array<Symbol>] one or more symbols representing mime type(s)
        #
        # @raise [Hanami::Controller::UnknownFormatError] if the symbol cannot
        #   be converted into a mime type
        #
        # @since 0.1.0
        #
        # @see Hanami::Controller::Configuration#format
        #
        # @example
        #   require 'hanami/controller'
        #
        #   class Show
        #     include Hanami::Action
        #     accept :html, :json
        #
        #     def call(params)
        #       # ...
        #     end
        #   end
        #
        #   # When called with "*/*"              => 200
        #   # When called with "text/html"        => 200
        #   # When called with "application/json" => 200
        #   # When called with "application/xml"  => 406
        def accept(*formats)
          @accepted_formats = *formats
          before :enforce_accepted_mime_types
        end

        # Handle the given exception with an HTTP status code.
        #
        # When the exception is raise during #call execution, it will be
        # translated into the associated HTTP status.
        #
        # This is a fine grained control, for a global configuration see
        # Hanami::Action.handled_exceptions
        #
        # @param exception [Hash] the exception class must be the key and the
        #   HTTP status the value of the hash
        #
        # @since 0.1.0
        #
        # @see Hanami::Action.handled_exceptions
        #
        # @example
        #   require 'hanami/controller'
        #
        #   class Show
        #     include Hanami::Action
        #     handle_exception RecordNotFound => 404
        #
        #     def call(params)
        #       # ...
        #       raise RecordNotFound.new
        #     end
        #   end
        #
        #   Show.new.call({id: 1}) # => [404, {}, ['Not Found']]
        def handle_exception(exception)
          handled_exceptions.merge!(exception)
        end

        # Returns a new action
        #
        # @overload new(**args)
        #   @param args [Hash] action dependencies
        #
        # @overload new(configuration:, **args)
        #   @param configuration [Hanami::Controller::Configuration] action configuration
        #   @param args [Hash] action dependencies
        #
        # @return [Hanami::Action] Action object
        #
        # @since 2.0.0
        def new(configuration: self.configuration, **args)
          allocate.tap do |obj|
            obj.instance_variable_set(:@name, Name[name])
            obj.instance_variable_set(:@configuration, configuration)
            obj.instance_variable_set(:@accepted_mime_types, Mime.restrict_mime_types(configuration, accepted_formats))
            obj.instance_variable_set(
              :@handled_exceptions,
              ::Hash[
                configuration
                .handled_exceptions
                .merge(handled_exceptions)
                .sort{ |(ex1,_),(ex2,_)| ex1.ancestors.include?(ex2) ? -1 : 1 }
              ]
            )
            obj.send(:initialize, **args)
            obj.freeze
          end
        end

        module Name
          MODULE_SEPARATOR_TRANSFORMER = [:gsub, "::", "."].freeze

          def self.call(name)
            Utils::String.transform(name, MODULE_SEPARATOR_TRANSFORMER, :underscore) unless name.nil?
          end

          class << self
            alias [] call
          end
        end
      end

      module InstanceMethods
        attr_reader :name

        # Implements the Rack/Hanami::Action protocol
        #
        # @since 0.1.0
        # @api private
        def call(env)
          request  = nil
          response = nil

          halted = catch :halt do
            begin
              params   = self.class.params_class.new(env)
              request  = build_request(env, params)
              response = build_response(
                request: request,
                action: name,
                configuration: configuration,
                content_type: Mime.calculate_content_type_with_charset(configuration, request, accepted_mime_types),
                env: env,
                header: configuration.default_headers
              )

              _run_before_callbacks(request, response)
              handle(request, response)
              _run_after_callbacks(request, response)
            rescue => exception
              _handle_exception(request, response, exception)
            end
          end

          finish(request, response, halted)
        end

        def initialize(**deps)
          @_deps = deps
        end

        # Returns a new copy of the action with new arguments merged with those
        # previously passed to `.new`
        #
        # @param new_args [Hash] new arguments
        #
        # @return [Hanami::Action] New action object
        #
        # @since 2.0.0
        def with(**new_args)
          self.class.new(@_deps.merge(new_args))
        end

        protected

        # Hook for subclasses to apply behavior as part of action invocation
        #
        # @param request [Hanami::Action::Request]
        # @param response [Hanami::Action::Response]
        #
        # @since 2.0.0
        def handle(request, response)
        end

        # Halt the action execution with the given HTTP status code and message.
        #
        # When used, the execution of a callback or of an action is interrupted
        # and the control returns to the framework, that decides how to handle
        # the event.
        #
        # If a message is provided, it sets the response body with the message.
        # Otherwise, it sets the response body with the default message associated
        # to the code (eg 404 will set `"Not Found"`).
        #
        # @param status [Fixnum] a valid HTTP status code
        # @param body [String] the response body
        #
        # @raise [StandardError] if the code isn't valid
        #
        # @since 0.2.0
        #
        # @see Hanami::Controller#handled_exceptions
        # @see Hanami::Action::Throwable#handle_exception
        # @see Hanami::Http::Status:ALL
        #
        # @example Basic usage
        #   require 'hanami/controller'
        #
        #   class Show
        #     def call(params)
        #       halt 404
        #     end
        #   end
        #
        #   # => [404, {}, ["Not Found"]]
        #
        # @example Custom message
        #   require 'hanami/controller'
        #
        #   class Show
        #     def call(params)
        #       halt 404, "This is not the droid you're looking for."
        #     end
        #   end
        #
        #   # => [404, {}, ["This is not the droid you're looking for."]]
        def halt(status, body = nil)
          Halt.call(status, body)
        end

        # @since 0.3.2
        # @api private
        def _requires_no_body?(res)
          HTTP_STATUSES_WITHOUT_BODY.include?(res.status)
        end

        # @since 2.0.0
        # @api private
        def _requires_empty_headers?(res)
          _requires_no_body?(res) || res.head?
        end

        private

        attr_reader :configuration

        def accepted_mime_types
          @accepted_mime_types || configuration.mime_types
        end

        def enforce_accepted_mime_types(req, *)
          Mime.accepted_mime_type?(req, accepted_mime_types, configuration) or halt 406
        end

        attr_reader :handled_exceptions

        def exception_handler(exception)
          handled_exceptions.each do |exception_class, handler|
            return handler if exception.kind_of?(exception_class)
          end

          nil
        end

        def build_request(env, params)
          Request.new(env, params)
        end

        def build_response(**options)
          Response.new(**options)
        end

        # @since 0.2.0
        # @api private
        def _reference_in_rack_errors(req, exception)
          req.env[RACK_EXCEPTION] = exception

          if errors = req.env[RACK_ERRORS]
            errors.write(_dump_exception(exception))
            errors.flush
          end
        end

        # @since 0.2.0
        # @api private
        def _dump_exception(exception)
          [[exception.class, exception.message].compact.join(": "), *exception.backtrace].join("\n\t")
        end

        # @since 0.1.0
        # @api private
        def _handle_exception(req, res, exception)
          handler = exception_handler(exception)

          if handler.nil?
            _reference_in_rack_errors(req, exception)
            raise exception
          end

          instance_exec(
            req,
            res,
            exception,
            &_exception_handler(handler)
          )

          nil
        end

        # @since 0.3.0
        # @api private
        def _exception_handler(handler)
          if respond_to?(handler.to_s, true)
            method(handler)
          else
            ->(*) { halt handler }
          end
        end

        # @since 0.1.0
        # @api private
        def _run_before_callbacks(*args)
          self.class.before_callbacks.run(self, *args)
          nil
        end

        # @since 0.1.0
        # @api private
        def _run_after_callbacks(*args)
          self.class.after_callbacks.run(self, *args)
          nil
        end

        # According to RFC 2616, when a response MUST have an empty body, it only
        # allows Entity Headers.
        #
        # For instance, a <tt>204</tt> doesn't allow <tt>Content-Type</tt> or any
        # other custom header.
        #
        # This restriction is enforced by <tt>Hanami::Action#_requires_no_body?</tt>.
        #
        # However, there are cases that demand to bypass this rule to set meta
        # informations via headers.
        #
        # An example is a <tt>DELETE</tt> request for a JSON API application.
        # It returns a <tt>204</tt> but still wants to specify the rate limit
        # quota via <tt>X-Rate-Limit</tt>.
        #
        # @since 0.5.0
        #
        # @see Hanami::Action#_requires_no_body?
        #
        # @example
        #   require 'hanami/controller'
        #
        #   module Books
        #     class Destroy
        #       include Hanami::Action
        #
        #       def call(params)
        #         # ...
        #         self.headers.merge!(
        #           'Last-Modified' => 'Fri, 27 Nov 2015 13:32:36 GMT',
        #           'X-Rate-Limit'  => '4000',
        #           'Content-Type'  => 'application/json',
        #           'X-No-Pass'     => 'true'
        #         )
        #
        #         self.status = 204
        #       end
        #
        #       private
        #
        #       def keep_response_header?(header)
        #         super || header == 'X-Rate-Limit'
        #       end
        #     end
        #   end
        #
        #   # Only the following headers will be sent:
        #   #  * Last-Modified - because we used `super' in the method that respects the HTTP RFC
        #   #  * X-Rate-Limit  - because we explicitely allow it
        #
        #   # Both Content-Type and X-No-Pass are removed because they're not allowed
        def keep_response_header?(header)
          ENTITY_HEADERS.include?(header)
        end

        # @since 2.0.0
        # @api private
        def _empty_headers(res)
          res.headers.select! { |header, _| keep_response_header?(header) }
        end

        def format(value)
          case value
          when Symbol
            format = Utils::Kernel.Symbol(value)
            [format, Action::Mime.format_to_mime_type(format, configuration)]
          when String
            [Action::Mime.detect_format(value, configuration), value]
          else
            raise Hanami::Controller::UnknownFormatError.new(value)
          end
        end

        # Raise error when `Hanami::Action::Session` isn't included.
        #
        # To use `session`, include `Hanami::Action::Session`.
        #
        # @raise [Hanami::Controller::MissingSessionError]
        #
        # @since 1.2.0
        def session
          raise Hanami::Controller::MissingSessionError.new(:session)
        end

        # Raise error when `Hanami::Action::Session` isn't included.
        #
        # To use `flash`, include `Hanami::Action::Session`.
        #
        # @raise [Hanami::Controller::MissingSessionError]
        #
        # @since 1.2.0
        def flash
          raise Hanami::Controller::MissingSessionError.new(:flash)
        end

        # Finalize the response
        #
        # This method is abstract and COULD be implemented by included modules in
        # order to prepare their data before the response will be returned to the
        # webserver.
        #
        # @since 0.1.0
        # @api private
        # @abstract
        #
        # @see Hanami::Action::Callable#finish
        # @see Hanami::Action::Session#finish
        # @see Hanami::Action::Cookies#finish
        # @see Hanami::Action::Cache#finish
        def finish(req, res, halted)
          res.status, res.body = *halted unless halted.nil?

          _empty_headers(res) if _requires_empty_headers?(res)

          res.set_format(Action::Mime.detect_format(res.content_type, configuration))
          res[:params] = req.params
          res[:format] = res.format
          res
        end
      end
    end
  end
end
