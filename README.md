# Hanami::Controller

Complete, fast and testable actions for Rack and [Hanami](http://hanamirb.org)

## Status

[![Gem Version](https://badge.fury.io/rb/hanami-controller.png)](http://badge.fury.io/rb/hanami-controller)
[![Build Status](https://secure.travis-ci.org/hanami/controller.png?branch=master)](http://travis-ci.org/hanami/controller?branch=master)
[![Coverage](https://coveralls.io/repos/hanami/controller/badge.png?branch=master)](https://coveralls.io/r/hanami/controller)
[![Code Climate](https://codeclimate.com/github/hanami/controller.png)](https://codeclimate.com/github/hanami/controller)
[![Dependencies](https://gemnasium.com/hanami/controller.png)](https://gemnasium.com/hanami/controller)
[![Inline docs](http://inch-ci.org/github/hanami/controller.png)](http://inch-ci.org/github/hanami/controller)

## Contact

* Home page: http://hanamirb.org
* Mailing List: http://hanamirb.org/mailing-list
* API Doc: http://rdoc.info/gems/hanami-controller
* Bugs/Issues: https://github.com/hanami/controller/issues
* Chat: http://chat.hanamirb.org
* Chat: https://gitter.im/hanami/chat

## Rubies

__Hanami::Controller__ supports Ruby (MRI) 2.2+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hanami-controller'
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install hanami-controller
```

## Usage

Hanami::Controller is a micro library for web frameworks.
It works beautifully with [Hanami::Router](https://github.com/hanami/router), but it can be employed everywhere.
It's designed to be fast and testable.

### Actions

The core of this framework are the actions.
They are the endpoints that respond to incoming HTTP requests.

```ruby
class Show
  include Hanami::Action

  def call(params)
    @article = Article.find params[:id]
  end
end
```

The usage of `Hanami::Action` follows the Hanami philosophy: include a module and implement a minimal interface.
In this case, the interface is one method: `#call(params)`.

Hanami is designed to not interfere with inheritance.
This is important, because you can implement your own initialization strategy.

__An action is an object__. That's important because __you have the full control on it__.
In other words, you have the freedom to instantiate, inject dependencies and test it, both at the unit and integration level.

In the example below, the default repository is `Article`. During a unit test we can inject a stubbed version, and invoke `#call` with the params.
__We're avoiding HTTP calls__, we're also going to avoid hitting the database (it depends on the stubbed repository), __we're just dealing with message passing__.
Imagine how **fast** the unit test could be.

```ruby
class Show
  include Hanami::Action

  def initialize(repository = Article)
    @repository = repository
  end

  def call(params)
    @article = @repository.find params[:id]
  end
end

action = Show.new(MemoryArticleRepository)
action.call({ id: 23 })
```

### Params

The request params are passed as an argument to the `#call` method.
If routed with *Hanami::Router*, it extracts the relevant bits from the Rack `env` (eg the requested `:id`).
Otherwise everything is passed as is: the full Rack `env` in production, and the given `Hash` for unit tests.

With Hanami::Router:

```ruby
class Show
  include Hanami::Action

  def call(params)
    # ...
    puts params # => { id: 23 } extracted from Rack env
  end
end
```

Standalone:

```ruby
class Show
  include Hanami::Action

  def call(params)
    # ...
    puts params # => { :"rack.version"=>[1, 2], :"rack.input"=>#<StringIO:0x007fa563463948>, ... }
  end
end
```

Unit Testing:

```ruby
class Show
  include Hanami::Action

  def call(params)
    # ...
    puts params # => { id: 23, key: 'value' } passed as it is from testing
  end
end

action   = Show.new
response = action.call({ id: 23, key: 'value' })
```

#### Whitelisting

Params represent an untrusted input.
For security reasons it's recommended to whitelist them.

```ruby
require 'hanami/controller'

class Signup
  include Hanami::Action

  params do
    param :first_name
    param :last_name
    param :email
    
    param :address do
      param :line_one
      param :state
      param :country
    end
  end

  def call(params)
    # Describe inheritance hierarchy
    puts params.class            # => Signup::Params
    puts params.class.superclass # => Hanami::Action::Params

    # Whitelist :first_name, but not :admin
    puts params[:first_name]     # => "Luca"
    puts params[:admin]          # => nil
    
    # Whitelist nested params [:address][:line_one], not [:address][:line_two]
    puts params[:address][:line_one] # => '69 Tender St'
    puts params[:address][:line_two] # => nil
  end
end
```

#### Validations & Coercions

Because params are a well defined set of data required to fulfill a feature
in your application, you can validate them. So you can avoid hitting lower MVC layers
when params are invalid.

If you specify the `:type` option, the param will be coerced.

```ruby
require 'hanami/controller'

class Signup
  MEGABYTE = 1024 ** 2
  include Hanami::Action

  params do
    param :first_name,       presence: true
    param :last_name,        presence: true
    param :email,            presence: true, format: /@/,   confirmation: true
    param :password,         presence: true,                confirmation: true
    param :terms_of_service, acceptance: true
    param :avatar,           size: 0..(MEGABYTE * 3)
    param :age,              type: Integer, size: 18..99
  end

  def call(params)
    halt 400 unless params.valid?
    # ...
  end
end

action = Signup.new

action.call(valid_params) # => [200, {}, ...]
action.errors.empty?      # => true

action.call(invalid_params) # => [400, {}, ...]
action.errors               # =>  #<Hanami::Validations::Errors:0x007fabe4b433d0 @errors={...}>

action.errors.for(:email)
  # => [#<Hanami::Validations::Error:0x007fabe4b432e0 @attribute=:email, @validation=:presence, @expected=true, @actual=nil>]
```

### Response

The output of `#call` is a serialized Rack::Response (see [#finish](http://rubydoc.info/github/rack/rack/master/Rack/Response#finish-instance_method)):

```ruby
class Show
  include Hanami::Action

  def call(params)
    # ...
  end
end

action = Show.new
action.call({}) # => [200, {}, [""]]
```

It has private accessors to explicitly set status, headers, and body:

```ruby
class Show
  include Hanami::Action

  def call(params)
    self.status  = 201
    self.body    = 'Hi!'
    self.headers.merge!({ 'X-Custom' => 'OK' })
  end
end

action = Show.new
action.call({}) # => [201, { "X-Custom" => "OK" }, ["Hi!"]]
```

### Exposures

We know that actions are objects and `Hanami::Action` respects one of the pillars of OOP: __encapsulation__.
Other frameworks extract instance variables (`@ivar`) and make them available to the view context.

`Hanami::Action`'s solution is the simple and powerful DSL: `expose`.
It's a thin layer on top of `attr_reader`.

Using `expose` creates a getter for the given attribute, and adds it to the _exposures_.
Exposures (`#exposures`) are a set of attributes exposed to the view.
That is to say the variables necessary for rendering a view.

By default, all `Hanami::Action` objects expose `#params` and `#errors`.

```ruby
class Show
  include Hanami::Action

  expose :article

  def call(params)
    @article = Article.find params[:id]
  end
end

action = Show.new
action.call({ id: 23 })

assert_equal 23, action.article.id

puts action.exposures # => { article: <Article:0x007f965c1d0318 @id=23> }
```

### Callbacks

It offers a powerful, inheritable callback chain which is executed before and/or after your `#call` method invocation:

```ruby
class Show
  include Hanami::Action

  before :authenticate, :set_article

  def call(params)
  end

  private
  def authenticate
    # ...
  end

  # `params` in the method signature is optional
  def set_article(params)
    @article = Article.find params[:id]
  end
end
```

Callbacks can also be expressed as anonymous lambdas:

```ruby
class Show
  include Hanami::Action

  before { ... } # do some authentication stuff
  before { |params| @article = Article.find params[:id] }

  def call(params)
  end
end
```

### Exceptions management

When an exception is raised, it automatically sets the HTTP status to [500](http://httpstatus.es/500):

```ruby
class Show
  include Hanami::Action

  def call(params)
    raise
  end
end

action = Show.new
action.call({}) # => [500, {}, ["Internal Server Error"]]
```

You can map a specific raised exception to a different HTTP status.

```ruby
class Show
  include Hanami::Action
  handle_exception RecordNotFound => 404

  def call(params)
    @article = Article.find params[:id]
  end
end

action = Show.new
action.call({id: 'unknown'}) # => [404, {}, ["Not Found"]]
```

You can also define custom handlers for exceptions.

```ruby
class Create
  include Hanami::Action
  handle_exception ArgumentError => :my_custom_handler

  def call(params)
    raise ArgumentError.new("Invalid arguments")
  end

  private
  def my_custom_handler(exception)
    status 400, exception.message
  end
end

action = Create.new
action.call({}) # => [400, {}, ["Invalid arguments"]]
```

Exception policies can be defined globally, **before** the controllers/actions
are loaded.

```ruby
Hanami::Controller.configure do
  handle_exception RecordNotFound => 404
end

class Show
  include Hanami::Action

  def call(params)
    @article = Article.find params[:id]
  end
end

action = Show.new
action.call({id: 'unknown'}) # => [404, {}, ["Not Found"]]
```

This feature can be turned off globally, in a controller or in a single action.

```ruby
Hanami::Controller.configure do
  handle_exceptions false
end

# or

module Articles
  class Show
    include Hanami::Action

    configure do
      handle_exceptions false
    end

    def call(params)
      @article = Article.find params[:id]
    end
  end
end

action = Articles::Show.new
action.call({id: 'unknown'}) # => raises RecordNotFound
```

#### Inherited Exceptions

```ruby
class MyCustomException < StandardError
end

module Articles
  class Index
    include Hanami::Action

    handle_exception MyCustomException => :handle_my_exception

    def call(params)
      raise MyCustomException
    end

    private

    def handle_my_exception
      # ...
    end
  end

  class Show
    include Hanami::Action

    handle_exception StandardError => :handle_standard_error

    def call(params)
      raise MyCustomException
    end

    private

    def handle_standard_error
      # ...
    end
  end
end

Articles::Index.new.call({}) # => `handle_my_exception` will be invoked
Articles::Show.new.call({})  # => `handle_standard_error` will be invoked,
                             #   because `MyCustomException` inherits from `StandardError`
```

### Throwable HTTP statuses

When `#halt` is used with a valid HTTP code, it stops the execution and sets the proper status and body for the response:

```ruby
class Show
  include Hanami::Action

  before :authenticate!

  def call(params)
    # ...
  end

  private
  def authenticate!
    halt 401 unless authenticated?
  end
end

action = Show.new
action.call({}) # => [401, {}, ["Unauthorized"]]
```

Alternatively, you can specify a custom message.

```ruby
class Show
  include Hanami::Action

  def call(params)
    DroidRepository.find(params[:id]) or not_found
  end

  private
  def not_found
    halt 404, "This is not the droid you're looking for"
  end
end

action = Show.new
action.call({}) # => [404, {}, ["This is not the droid you're looking for"]]
```

### Cookies

Hanami::Controller offers convenient access to cookies.

They are read as a Hash from Rack env:

```ruby
require 'hanami/controller'
require 'hanami/action/cookies'

class ReadCookiesFromRackEnv
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    # ...
    cookies[:foo] # => 'bar'
  end
end

action = ReadCookiesFromRackEnv.new
action.call({'HTTP_COOKIE' => 'foo=bar'})
```

They are set like a Hash:

```ruby
require 'hanami/controller'
require 'hanami/action/cookies'

class SetCookies
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    # ...
    cookies[:foo] = 'bar'
  end
end

action = SetCookies.new
action.call({}) # => [200, {'Set-Cookie' => 'foo=bar'}, '...']
```

They are removed by setting their value to `nil`:

```ruby
require 'hanami/controller'
require 'hanami/action/cookies'

class RemoveCookies
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    # ...
    cookies[:foo] = nil
  end
end

action = RemoveCookies.new
action.call({}) # => [200, {'Set-Cookie' => "foo=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000"}, '...']
```

Default values can be set in configuration, but overriden case by case.

```ruby
require 'hanami/controller'
require 'hanami/action/cookies'

Hanami::Controller.configure do
  cookies max_age: 300 # 5 minutes
end

class SetCookies
  include Hanami::Action
  include Hanami::Action::Cookies

  def call(params)
    # ...
    cookies[:foo] = { value: 'bar', max_age: 100 }
  end
end

action = SetCookies.new
action.call({}) # => [200, {'Set-Cookie' => "foo=bar; max-age=100;"}, '...']
```

### Sessions

It has builtin support for Rack sessions:

```ruby
require 'hanami/controller'
require 'hanami/action/session'

class ReadSessionFromRackEnv
  include Hanami::Action
  include Hanami::Action::Session

  def call(params)
    # ...
    session[:age] # => '31'
  end
end

action = ReadSessionFromRackEnv.new
action.call({ 'rack.session' => { 'age' => '31' }})
```

Values can be set like a Hash:

```ruby
require 'hanami/controller'
require 'hanami/action/session'

class SetSession
  include Hanami::Action
  include Hanami::Action::Session

  def call(params)
    # ...
    session[:age] = 31
  end
end

action = SetSession.new
action.call({}) # => [200, {"Set-Cookie"=>"rack.session=..."}, "..."]
```

Values can be removed like a Hash:

```ruby
require 'hanami/controller'
require 'hanami/action/session'

class RemoveSession
  include Hanami::Action
  include Hanami::Action::Session

  def call(params)
    # ...
    session[:age] = nil
  end
end

action = RemoveSession.new
action.call({}) # => [200, {"Set-Cookie"=>"rack.session=..."}, "..."] it removes that value from the session
```

While Hanami::Controller supports sessions natively, it's __session store agnostic__.
You have to specify the session store in your Rack middleware configuration (eg `config.ru`).

```ruby
use Rack::Session::Cookie, secret: SecureRandom.hex(64)
run Show.new
```

### Http Cache

Hanami::Controller sets your headers correctly according to RFC 2616 / 14.9 for more on standard cache control directives: http://tools.ietf.org/html/rfc2616#section-14.9.1

You can easily set the Cache-Control header for your actions:

```ruby
require 'hanami/controller'
require 'hanami/action/cache'

class HttpCacheController
  include Hanami::Action
  include Hanami::Action::Cache

  cache_control :public, max_age: 600 # => Cache-Control: public, max-age=600

  def call(params)
    # ...
  end
end
```

Expires header can be specified using `expires` method:

```ruby
require 'hanami/controller'
require 'hanami/action/cache'

class HttpCacheController
  include Hanami::Action
  include Hanami::Action::Cache

  expires 60, :public, max_age: 600 # => Expires: Sun, 03 Aug 2014 17:47:02 GMT, Cache-Control: public, max-age=600

  def call(params)
    # ...
  end
end
```

### Conditional Get

According to HTTP specification, conditional GETs provide a way for web servers to inform clients that the response to a GET request hasn't change since the last request returning a Not Modified header (304).

Passing the HTTP_IF_NONE_MATCH (content identifier) or HTTP_IF_MODIFIED_SINCE (timestamp) headers allows the web server define if the client has a fresh version of a given resource.

You can easily take advantage of Conditional Get using `#fresh` method:

```ruby
require 'hanami/controller'
require 'hanami/action/cache'

class ConditionalGetController
  include Hanami::Action
  include Hanami::Action::Cache

  def call(params)
    # ...
    fresh etag: @resource.cache_key
    # => halt 304 with header IfNoneMatch = @resource.cache_key
  end
end
```

If `@resource.cache_key` is equal to `IfNoneMatch` header, then hanami will `halt 304`.

The same behavior is accomplished using `last_modified`:

```ruby
require 'hanami/controller'
require 'hanami/action/cache'

class ConditionalGetController
  include Hanami::Action
  include Hanami::Action::Cache

  def call(params)
    # ...
    fresh last_modified: @resource.update_at
    # => halt 304 with header IfModifiedSince = @resource.update_at.httpdate
  end
end
```

If `@resource.update_at` is equal to `IfModifiedSince` header, then hanami will `halt 304`.

### Redirect

If you need to redirect the client to another resource, use `#redirect_to`:

```ruby
class Create
  include Hanami::Action

  def call(params)
    # ...
    redirect_to 'http://example.com/articles/23'
  end
end

action = Create.new
action.call({ article: { title: 'Hello' }}) # => [302, {'Location' => '/articles/23'}, '']
```

You can also redirect with a custom status code:

```ruby
class Create
  include Hanami::Action

  def call(params)
    # ...
    redirect_to 'http://example.com/articles/23', status: 301
  end
end

action = Create.new
action.call({ article: { title: 'Hello' }}) # => [301, {'Location' => '/articles/23'}, '']
```

### MIME Types

`Hanami::Action` automatically sets the `Content-Type` header, according to the request.

```ruby
class Show
  include Hanami::Action

  def call(params)
  end
end

action = Show.new

action.call({ 'HTTP_ACCEPT' => '*/*' }) # Content-Type "application/octet-stream"
action.format                           # :all

action.call({ 'HTTP_ACCEPT' => 'text/html' }) # Content-Type "text/html"
action.format                                 # :html
```

However, you can force this value:

```ruby
class Show
  include Hanami::Action

  def call(params)
    # ...
    self.format = :json
  end
end

action = Show.new

action.call({ 'HTTP_ACCEPT' => '*/*' }) # Content-Type "application/json"
action.format                           # :json

action.call({ 'HTTP_ACCEPT' => 'text/html' }) # Content-Type "application/json"
action.format                                 # :json
```

You can restrict the accepted MIME types:

```ruby
class Show
  include Hanami::Action
  accept :html, :json

  def call(params)
    # ...
  end
end

# When called with "\*/\*"            => 200
# When called with "text/html"        => 200
# When called with "application/json" => 200
# When called with "application/xml"  => 406
```

You can check if the requested MIME type is accepted by the client.

```ruby
class Show
  include Hanami::Action

  def call(params)
    # ...
    # @_env['HTTP_ACCEPT'] # => 'text/html,application/xhtml+xml,application/xml;q=0.9'

    accept?('text/html')        # => true
    accept?('application/xml')  # => true
    accept?('application/json') # => false
    self.format                 # :html



    # @_env['HTTP_ACCEPT'] # => '*/*'

    accept?('text/html')        # => true
    accept?('application/xml')  # => true
    accept?('application/json') # => true
    self.format                 # :html
  end
end
```

Hanami::Controller is shipped with an extensive list of the most common MIME types.
Also, you can register your own:

```ruby
Hanami::Controller.configure do
  format custom: 'application/custom'
end

class Index
  include Hanami::Action

  def call(params)
  end
end

action = Index.new

action.call({ 'HTTP_ACCEPT' => 'application/custom' }) # => Content-Type 'application/custom'
action.format                                          # => :custom

class Show
  include Hanami::Action

  def call(params)
    # ...
    self.format = :custom
  end
end

action = Show.new

action.call({ 'HTTP_ACCEPT' => '*/*' }) # => Content-Type 'application/custom'
action.format                           # => :custom
```

### Streamed Responses

When the work to be done by the server takes time, it may be a good idea to stream your response. Here's an example of a streamed CSV.

```ruby
Hanami::Controller.configure do
  format csv: 'text/csv'
  middleware.use ::Rack::Chunked
end

class Csv
  include Hanami::Action

  def call(params)
    self.format = :csv
    self.body = Enumerator.new do |yielder|
      yielder << csv_header
      
      # Expensive operation is streamed as each line becomes available
      csv_body.each_line do |line|
        yielder << line
      end
    end
  end
end
```

Note: 
* In development, Hanami' code reloading needs to be disabled for streaming to work. This is because `Shotgun` interferes with the streaming action. You can disable it like this `hanami server --code-reloading=false`
* Streaming does not work with WEBrick as it buffers its response. We recommend using `puma`, though you may find success with other servers

### No rendering, please

Hanami::Controller is designed to be a pure HTTP endpoint, rendering belongs to other layers of MVC.
You can set the body directly (see [response](#response)), or use [Hanami::View](https://github.com/hanami/view).

### Controllers

A Controller is nothing more than a logical group of actions: just a Ruby module.

```ruby
module Articles
  class Index
    include Hanami::Action

    # ...
  end

  class Show
    include Hanami::Action

    # ...
  end
end

Articles::Index.new.call({})
```

### Hanami::Router integration

While Hanami::Router works great with this framework, Hanami::Controller doesn't depend on it.
You, the developer, are free to choose your own routing system.

But, if you use them together, the **only constraint is that an action must support _arity 0_ in its constructor**.
The following examples are valid constructors:

```ruby
def initialize
end

def initialize(repository = Article)
end

def initialize(repository: Article)
end

def initialize(options = {})
end

def initialize(*args)
end
```

__Please note that this is subject to change: we're working to remove this constraint.__

Hanami::Router supports lazy loading for controllers. While this policy can be a
convenient fallback, you should know that it's the slower option. **Be sure of
loading your controllers before you initialize the router.**


### Rack integration

Hanami::Controller is compatible with Rack. However, it doesn't mount any middleware.
While a Hanami application's architecture is more web oriented, this framework is designed to build pure HTTP endpoints.

### Rack middleware

Rack middleware can be configured globally in `config.ru`. However, consider that they often add
unnecessary overhead for *all* endpoints that aren't direct users of all the configured middleware.

Think about a middleware to create sessions, where only `SessionsController::Create` needs that middleware, but every other action pays the performance price for that middleware.

The solution is that an action can employ one or more Rack middleware, with `.use`.

```ruby
require 'hanami/controller'

module Sessions
  class Create
    include Hanami::Action
    use OmniAuth

    def call(params)
      # ...
    end
  end
end
```

```ruby
require 'hanami/controller'

module Sessions
  class Create
    include Hanami::Controller

    use XMiddleware.new('x', 123)
    use YMiddleware.new
    use ZMiddleware

    def call(params)
      # ...
    end
  end
end
```

### Configuration

Hanami::Controller can be configured with a DSL.
It supports a few options:

```ruby
require 'hanami/controller'

Hanami::Controller.configure do
  # Handle exceptions with HTTP statuses (true) or don't catch them (false)
  # Argument: boolean, defaults to `true`
  #
  handle_exceptions true

  # If the given exception is raised, return that HTTP status
  # It can be used multiple times
  # Argument: hash, empty by default
  #
  handle_exception ArgumentError => 404

  # Register a format to MIME type mapping
  # Argument: hash, key: format symbol, value: MIME type string, empty by default
  #
  format custom: 'application/custom'

  # Define a fallback format to detect in case of HTTP request with `Accept: */*`
  # If not defined here, it will return Rack's default: `application/octet-stream`
  # Argument: symbol, it should be already known. defaults to `nil`
  #
  default_request_format :html

  # Define a default format to set as `Content-Type` header for response,
  # unless otherwise specified.
  # If not defined here, it will return Rack's default: `application/octet-stream`
  # Argument: symbol, it should be already known. defaults to `nil`
  #
  default_response_format :html

  # Define a default charset to return in the `Content-Type` response header
  # If not defined here, it returns `utf-8`
  # Argument: string, defaults to `nil`
  #
  default_charset 'koi8-r'

  # Configure the logic to be executed when Hanami::Action is included
  # This is useful to DRY code by having a single place where to configure
  # shared behaviors like authentication, sessions, cookies etc.
  # Argument: proc
  #
  prepare do
    include Hanami::Action::Sessions
    include MyAuthentication
    use SomeMiddleWare

    before { authenticate! }
  end
end
```

All of the global configurations can be overwritten at the controller level.
Each controller and action has its own copy of the global configuration.

This means changes are inherited from the top to the bottom, but do not bubble back up.

```ruby
require 'hanami/controller'

Hanami::Controller.configure do
  handle_exception ArgumentError => 400
end

module Articles
  class Create
    include Hanami::Action

    configure do
      handle_exceptions false
    end

    def call(params)
      raise ArgumentError
    end
  end
end

module Users
  class Create
    include Hanami::Action

    def call(params)
      raise ArgumentError
    end
  end
end

Users::Create.new.call({}) # => HTTP 400

Articles::Create.new.call({})
  # => raises ArgumentError because we set handle_exceptions to false
```

### Thread safety

An Action is **mutable**. When used without Hanami::Router, be sure to instantiate an
action for each request. The same advice applies when using
Hanami::Router but NOT routing to `mycontroller#myaction` but instead
routing direct to a class.

```ruby
# config.ru
require 'hanami/controller'

class Action
  include Hanami::Action

  def self.call(env)
    new.call(env)
  end

  def call(params)
    self.body = object_id.to_s
  end
end

run Action
```

Hanami::Controller heavely depends on class configuration. To ensure immutability
in deployment environments, use `Hanami::Controller.load!`.

## Versioning

__Hanami::Controller__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright © 2014-2016 Luca Guidi – Released under MIT License

This project was formerly known as Lotus (`lotus-controller`).
