# Lotus::Controller

A Rack compatible Controller layer for [Lotus](http://lotusrb.org).

## Status

[![Gem Version](https://badge.fury.io/rb/lotus-controller.png)](http://badge.fury.io/rb/lotus-controller)
[![Build Status](https://secure.travis-ci.org/lotus/controller.png?branch=master)](http://travis-ci.org/lotus/controller?branch=master)
[![Coverage](https://coveralls.io/repos/lotus/controller/badge.png?branch=master)](https://coveralls.io/r/lotus/controller)
[![Code Climate](https://codeclimate.com/github/lotus/controller.png)](https://codeclimate.com/github/lotus/controller)
[![Dependencies](https://gemnasium.com/lotus/controller.png)](https://gemnasium.com/lotus/controller)
[![Inline docs](http://inch-ci.org/github/lotus/controller.png)](http://inch-ci.org/github/lotus/controller)

## Contact

* Home page: http://lotusrb.org
* Mailing List: http://lotusrb.org/mailing-list
* API Doc: http://rdoc.info/gems/lotus-controller
* Bugs/Issues: https://github.com/lotus/controller/issues
* Support: http://stackoverflow.com/questions/tagged/lotus-ruby
* Chat: https://gitter.im/lotus/chat

## Rubies

__Lotus::Controller__ supports Ruby (MRI) 2+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lotus-controller'
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install lotus-controller
```

## Usage

Lotus::Controller is a micro library for web frameworks.
It works beautifully with [Lotus::Router](https://github.com/lotus/router), but it can be employed everywhere.
It's designed to be fast and testable.

### Actions

The core of this frameworks are the actions.
They are the endpoint that responds to incoming HTTP requests.

```ruby
class Show
  include Lotus::Action

  def call(params)
    @article = Article.find params[:id]
  end
end
```

The usage of `Lotus::Action` follows the Lotus philosophy: include a module and implement a minimal interface.
In this case, it's only one method: `#call(params)`.

Lotus is designed to not interfere with inheritance.
This is important, because you can implement your own initialization strategy.

__An action is an object__ after all, it's important that __you have the full control on it__.
In other words, you have the freedom of instantiate, inject dependencies and test it, both with unit and integration.

In the example below, we're stating that the default repository is `Article`, but during an unit test we can inject a stubbed version, and invoke `#call` with the params that we want to simulate.
__We're avoiding HTTP calls__, we're eventually avoiding to hit the database (it depends on the stubbed repository), __we're just dealing with message passing__.
Imagine how **fast** can be a unit test like this.

```ruby
class Show
  include Lotus::Action

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
If routed with *Lotus::Router*, it extracts the relevant bits from the Rack `env` (eg the requested `:id`).
Otherwise everything it's passed as it is: the full Rack `env` in production, and the given `Hash` for unit tests.

With Lotus::Router:

```ruby
class Show
  include Lotus::Action

  def call(params)
    # ...
    puts params # => { id: 23 } extracted from Rack env
  end
end
```

Standalone:

```ruby
class Show
  include Lotus::Action

  def call(params)
    # ...
    puts params # => { :"rack.version"=>[1, 2], :"rack.input"=>#<StringIO:0x007fa563463948>, ... }
  end
end
```

Unit Testing:

```ruby
class Show
  include Lotus::Action

  def call(params)
    # ...
    puts params # => { id: 23, key: 'value' } passed as it is from testing
  end
end

action   = Show.new
response = action.call({ id: 23, key: 'value' })
```

#### Whitelisting

Params represent an untrusted input, for security reasons it's recommended to
whitelist them.

```ruby
require 'lotus/controller'

class Signup
  include Lotus::Action

  params do
    param :first_name
    param :last_name
    param :email
  end

  def call(params)
    # Describe inheritance hierarchy
    puts params.class            # => Signup::Params
    puts params.class.superclass # => Lotus::Action::Params

    # Whitelist :first_name, but not :admin
    puts params[:first_name]     # => "Luca"
    puts params[:admin]          # => nil
  end
end
```

#### Validations & Coercions

Because params are a well defined set of data required to fulfill a feature
in your application, you can validate them and avoid to hit lower MVC layers
when they are invalid.

If you specify the `:type` option, the param will be coerced.

```ruby
require 'lotus/controller'

class Signup
  MEGABYTE = 1024 ** 2
  include Lotus::Action

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
action.errors               # =>  #<Lotus::Validations::Errors:0x007fabe4b433d0 @errors={...}>

action.errors.for(:email)
  # => [#<Lotus::Validations::Error:0x007fabe4b432e0 @attribute=:email, @validation=:presence, @expected=true, @actual=nil>]
```

### Response

The output of `#call` is a serialized Rack::Response (see [#finish](http://rubydoc.info/github/rack/rack/master/Rack/Response#finish-instance_method)):

```ruby
class Show
  include Lotus::Action

  def call(params)
    # ...
  end
end

action = Show.new
action.call({}) # => [200, {}, [""]]
```

It has private accessors to explicitly set status, headers and body:

```ruby
class Show
  include Lotus::Action

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

We know that actions are objects and Lotus::Action respects one of the pillars of OOP: __encapsulation__.
Other frameworks extract instance variables (`@ivar`) and make them available to the view context.
The solution of Lotus::Action is a simple and powerful DSL: `expose`.
It's a thin layer on top of `attr_reader`. When used, it creates a getter for the given attribute, and adds it to the _exposures_.
Exposures (`#exposures`) is set of exposed attributes, so that the view context can have the information needed to render a page.

By default, all the actions expose `#params` and `#errors`.

```ruby
class Show
  include Lotus::Action

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

It offers powerful, inheritable callbacks chain which is executed before and/or after your `#call` method invocation:

```ruby
class Show
  include Lotus::Action

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
  include Lotus::Action

  before { ... } # do some authentication stuff
  before {|params| @article = Article.find params[:id] }

  def call(params)
  end
end
```

### Exceptions management

When an exception is raised, it automatically sets the HTTP status to [500](http://httpstatus.es/500):

```ruby
class Show
  include Lotus::Action

  def call(params)
    raise
  end
end

action = Show.new
action.call({}) # => [500, {}, ["Internal Server Error"]]
```

You can define how a specific raised exception should be transformed in an HTTP status.

```ruby
class Show
  include Lotus::Action
  handle_exception RecordNotFound => 404

  def call(params)
    @article = Article.find params[:id]
  end
end

action = Show.new
action.call({id: 'unknown'}) # => [404, {}, ["Not Found"]]
```

Exception policies can be defined globally, **before** the controllers/actions
are loaded.

```ruby
Lotus::Controller.configure do
  handle_exception RecordNotFound => 404
end

class Show
  include Lotus::Action

  def call(params)
    @article = Article.find params[:id]
  end
end

action = Show.new
action.call({id: 'unknown'}) # => [404, {}, ["Not Found"]]
```

This feature can be turned off globally, in a controller or in a single action.

```ruby
Lotus::Controller.configure do
  handle_exceptions false
end

# or

class ArticlesController
  include Lotus::Controller

  configure do
    handle_exceptions false
  end

  action 'Show' do
    def call(params)
      @article = Article.find params[:id]
    end
  end
end

action = ArticlesController::Show.new
action.call({id: 'unknown'}) # => raises RecordNotFound
```

### Throwable HTTP statuses

When `#halt` is used with a valid HTTP code, it stops the execution and sets the proper status and body for the response:

```ruby
class Show
  include Lotus::Action

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

### Cookies

It offers convenient access to cookies.

They are read as a Hash from Rack env:

```ruby
require 'lotus/controller'
require 'lotus/action/cookies'

class ReadCookiesFromRackEnv
  include Lotus::Action
  include Lotus::Action::Cookies

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
require 'lotus/controller'
require 'lotus/action/cookies'

class SetCookies
  include Lotus::Action
  include Lotus::Action::Cookies

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
require 'lotus/controller'
require 'lotus/action/cookies'

class RemoveCookies
  include Lotus::Action
  include Lotus::Action::Cookies

  def call(params)
    # ...
    cookies[:foo] = nil
  end
end

action = SetCookies.new
action.call({}) # => [200, {'Set-Cookie' => "foo=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000"}, '...']
```

### Sessions

It has builtin support for Rack sessions:

```ruby
require 'lotus/controller'
require 'lotus/action/session'

class ReadSessionFromRackEnv
  include Lotus::Action
  include Lotus::Action::Session

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
require 'lotus/controller'
require 'lotus/action/session'

class SetSession
  include Lotus::Action
  include Lotus::Action::Session

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
require 'lotus/controller'
require 'lotus/action/session'

class RemoveSession
  include Lotus::Action
  include Lotus::Action::Session

  def call(params)
    # ...
    session[:age] = nil
  end
end

action = RemoveSession.new
action.call({}) # => [200, {"Set-Cookie"=>"rack.session=..."}, "..."] it removes that value from the session
```

While Lotus::Controller supports sessions natively, it's __session store agnostic__.
You have to specify the session store in your Rack middleware configuration (eg `config.ru`).

```ruby
use Rack::Session::Cookie, secret: SecureRandom.hex(64)
run Show.new
```

### Http Cache

It sets your headers correctly according to RFC 2616 / 14.9 for more on standard cache control directives: http://tools.ietf.org/html/rfc2616#section-14.9.1

You can easily set the Cache-Control header for your actions:

```ruby
require 'lotus/controller'
require 'lotus/action/cache'

class HttpCacheController
  include Lotus::Action
  include Lotus::Action::Cache

  cache_control :public, max_age: 600 # => Cache-Control: public, max-age=600

  def call(params)
    # ...
  end
end
```

Expires header can be specified using `expires` method:

```ruby
require 'lotus/controller'
require 'lotus/action/cache'

class HttpCacheController
  include Lotus::Action
  include Lotus::Action::Cache

  expires 60, :public, max_age: 600 # => Expires: Sun, 03 Aug 2014 17:47:02 GMT, Cache-Control: public, max-age=600

  def call(params)
    # ...
  end
end
```

### Conditional Get
According to HTTP specification, conditional gets provide a way for web servers to inform clients that the response to a GET request hasn't change since the last request returning a Not Modified header (304).

Passing the HTTP_IF_NONE_MATCH (content identifier) or HTTP_IF_MODIFIED_SINCE (timestamp) headers allows the web server define if the client has a fresh version of a given resource.

You can easily take advantage of Conditional Get using `#fresh` method:

```ruby
require 'lotus/controller'
require 'lotus/action/cache'

class ConditionalGetController
  include Lotus::Action
  include Lotus::Action::Cache

  def call(params)
    # ...
    fresh etag: @resource.cache_key
    # => halt 304 with header IfNoneMatch = @resource.cache_key
  end
end
```

If `@resource.cache_key` is equal to `IfNoneMatch` header, then lotus will `halt 304`.

The same behavior is accomplished using `last_modified`:

```ruby
require 'lotus/controller'
require 'lotus/action/cache'

class ConditionalGetController
  include Lotus::Action
  include Lotus::Action::Cache

  def call(params)
    # ...
    fresh last_modified: @resource.update_at
    # => halt 304 with header IfModifiedSince = @resource.update_at.httpdate
  end
end
```

If `@resource.update_at` is equal to `IfModifiedSince` header, then lotus will `halt 304`.

### Redirect

If you need to redirect the client to another resource, use `#redirect_to`:

```ruby
class Create
  include Lotus::Action

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
  include Lotus::Action

  def call(params)
    # ...
    redirect_to 'http://example.com/articles/23', status: 301
  end
end

action = Create.new
action.call({ article: { title: 'Hello' }}) # => [301, {'Location' => '/articles/23'}, '']
```

### Mime types

Lotus::Action automatically sets the `Content-Type` header, according to the request.

```ruby
class Show
  include Lotus::Action

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
  include Lotus::Action

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

You can restrict the accepted mime types:

```ruby
class Show
  include Lotus::Action
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

You can check if the requested mime type is accepted by the client.

```ruby
class Show
  include Lotus::Action

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

Lotus::Controller is shipped with an extensive list of the most common mime types.
Also, you can register your own:

```ruby
Lotus::Controller.configure do
  format custom: 'application/custom'
end

class Index
  include Lotus::Action

  def call(params)
  end
end

action = Index.new

action.call({ 'HTTP_ACCEPT' => 'application/custom' }) # => Content-Type 'application/custom'
action.format                                          # => :custom

class Show
  include Lotus::Action

  def call(params)
    # ...
    self.format = :custom
  end
end

action = Show.new

action.call({ 'HTTP_ACCEPT' => '*/*' }) # => Content-Type 'application/custom'
action.format                           # => :custom
```

### No rendering, please

Lotus::Controller is designed to be a pure HTTP endpoint, rendering belongs to other layers of MVC.
You can set the body directly (see [response](#response)), or use [Lotus::View](https://github.com/lotus/view).

### Controllers

A Controller is nothing more than a logical group for actions.

```ruby
class ArticlesController
  class Index
    include Lotus::Action

    # ...
  end

  class Show
    include Lotus::Action

    # ...
  end
end
```

Which is a bit verbose. Instead, just do:

```ruby
class ArticlesController
  include Lotus::Controller

  action 'Index' do
    # ...
  end

  action 'Show' do
    # ...
  end
end

ArticlesController::Index.new.call({})
```

### Lotus::Router integration

While Lotus::Router works great with this framework, Lotus::Controller doesn't depend from it.
You, as developer, are free to choose your own routing system.

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

Lotus::Router supports lazy loading for controllers. While this policy can be a
convenient fallback, you should know that it's the slower option. **Be sure of
loading your controllers before you initialize the router.**


### Rack integration

Lotus::Controller is compatible with Rack. However, it doesn't mount any middleware.
While a Lotus application's architecture is more web oriented, this framework is designed to build pure HTTP endpoints.

### Rack middleware

Rack middleware can be configured globally in `config.ru`, but often they add an
unnecessary overhead for all those endpoints who aren't direct users of a
certain middleware. Think about a middleware to create sessions, where only
`SessionsController::Create` may be involved and the rest of the application
shouldn't pay the performance ticket of calling that middleware.

An action can employ one or more Rack middleware, with `.use`.

```ruby
require 'lotus/controller'

class SessionsController
  include Lotus::Controller

  action 'Create' do
    use OmniAuth

    def call(params)
      # ...
    end
  end
end
```

```ruby
require 'lotus/controller'

class SessionsController
  include Lotus::Controller

  action 'Create' do
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

Lotus::Controller can be configured with a DSL that determines its behavior.
It supports a few options:

```ruby
require 'lotus/controller'

Lotus::Controller.configure do
  # Handle exceptions with HTTP statuses (true) or don't catch them (false)
  # Argument: boolean, defaults to true
  #
  handle_exceptions true

  # If the given exception is raised, return that HTTP status
  # It can be used multiple times
  # Argument: hash, empty by default
  #
  handle_exception ArgumentError => 404

  # Configure which module to include when Lotus::Controller.action is used
  # Argument: module, defaults to Lotus::Action
  #
  action_module MyApp::Action # module, defaults to Lotus::Action

  # Register a format to mime type mapping
  # Argument: hash, key: format symbol, value: mime type string, empty by default
  #
  format custom: 'application/custom'

  # Configure the modules to be included/extended/prepended by default.
  # Argument: proc, empty by default
  #
  modules do
    include Lotus::Action::Sessions
    prepend MyLibrary::Session::Store
  end
end
```

All those global configurations can be overwritten at a finer grained level:
controllers. Each controller and action has its own copy of the global
configuration, so that changes are inherited from the top to the bottom, but
not bubbled up in the opposite direction.

```ruby
require 'lotus/controller'

Lotus::Controller.configure do
  handle_exception ArgumentError => 400
end

class ArticlesController
  include Lotus::Controller

  configure do
    handle_exceptions false
  end

  action 'Create' do
    def call(params)
      raise ArgumentError
    end
  end
end

class UsersController
  include Lotus::Controller

  action 'Create' do
    def call(params)
      raise ArgumentError
    end
  end
end

UsersController::Create.new.call({}) # => HTTP 400

ArticlesController::Create.new.call({})
  # => raises ArgumentError because we set handle_exceptions to false
```

### Reusability

Lotus::Controller can be used as a singleton framework as seen in this README.
The application code includes `Lotus::Controller` or `Lotus::Action` directly
and the configuration is unique per Ruby process.

While this is convenient for tiny applications, it doesn't fit well for more
complex scenarios, where we want micro applications to coexist together.

```ruby
require 'lotus/controller'

module WebApp
  Controller = Lotus::Controller.duplicate
end

module ApiApp
  Controller = Lotus::Controller.duplicate(self) do
    handle_exception ArgumentError => 400
  end
end
```

The code above defines `WebApp::Controller` and `WebApp::Action`, to be used for
the `WebApp` endpoints, while `ApiApp::Controller` and `ApiApp::Action` have
a different configuration.

### Thread safety

An Action is **mutable**. When used without Lotus::Router, be sure to instantiate an
action for each request.

```ruby
# config.ru
require 'lotus/controller'

class Action
  include Lotus::Action

  def self.call(env)
    new.call(env)
  end

  def call(params)
    self.body = object_id.to_s
  end
end

run Action
```

## Versioning

__Lotus::Controller__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright 2014 Luca Guidi – Released under MIT License
