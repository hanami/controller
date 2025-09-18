# Hanami::Controller

Complete, fast, and testable actions for Rack and [Hanami](http://hanamirb.org)

## Status

[![Gem Version](https://badge.fury.io/rb/hanami-controller.svg)](https://badge.fury.io/rb/hanami-controller)
[![CI](https://github.com/hanami/controller/actions/workflows/ci.yml/badge.svg)](https://github.com/hanami/controller/actions?query=workflow%3Aci+branch%3Amain)
[![Test Coverage](https://codecov.io/gh/hanami/controller/branch/main/graph/badge.svg)](https://codecov.io/gh/hanami/controller)
[![Depfu](https://badges.depfu.com/badges/7cd17419fba78b726be1353118fb01de/overview.svg)](https://depfu.com/github/hanami/controller?project=Bundler)

## Contact

* Home page: http://hanamirb.org
* Community: http://hanamirb.org/community
* Guides: https://guides.hanamirb.org
* Mailing List: http://hanamirb.org/mailing-list
* API Doc: http://rubydoc.info/gems/hanami-controller
* Chat: http://chat.hanamirb.org


## Installation

__Hanami::Controller__ supports Ruby (MRI) 3.1+

Add this line to your application's Gemfile:

```ruby
gem "hanami-controller"
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
class Show < Hanami::Action
  def handle(request, response)
    response[:article] = ArticleRepo.new.find(request.params[:id])
  end
end
```

`Hanami::Action` follows the Hanami philosophy: a single purpose object with a minimal interface.

In this case, `Hanami::Action` provides the key public interface of `#call(env)`, making your actions Rack-compatible.
To provide custom behaviour when your actions are being called, you can implement `#handle(request, response)`

**An action is an object** and **you have full control over it**.
In other words, you have the freedom to instantiate, inject dependencies and test it, both at the unit and integration level.

In the example below, the default repo is `ArticleRepo`. During a unit test we can inject a stubbed version, and invoke `#call` with the params.
__We're avoiding HTTP calls__, we're also going to avoid hitting the database (it depends on the stubbed repo), __we're just dealing with message passing__.
Imagine how **fast** the unit test could be.

```ruby
class Show < Hanami::Action
  def initialize(repo: ArticleRepo.new, **)
    @repo = repo
    super(**)
  end

  def handle(request, response)
    response[:article] = repo.find(request.params[:id])
  end

  private

  attr_reader :repo
end

action = Show.new(repo: ArticleRepo.new)
action.call(id: 23)
```

### Params

The request params are part of the request passed as an argument to the `#handle` method.

There are three scenarios for how params are extracted:

**With Hanami::Router:**
When routed with *Hanami::Router*, it extracts and merges route parameters, query string parameters, and form parameters (with router params taking precedence).

```ruby
class Show < Hanami::Action
  def handle(request, response)
    # ...
    puts request.params.to_h # => {id: 23, name: "john", age: "25"}
  end
end

# When called via router with route "/users/:id" and query string "?name=john&age=25"
Show.new.call({
  "router.params" => {id: 23},
  "QUERY_STRING" => "name=john&age=25"
})
```

**With Rack environment:**
When used in a Rack application (but without Hanami::Router), it extracts query string and form parameters from the request.

```ruby
class Show < Hanami::Action
  def handle(request, response)
    # ...
    puts request.params.to_h # => {name: "john", age: "25"} from query/form
  end
end

# When called with Rack env containing rack.input
Show.new.call({
  "rack.input" => StringIO.new("name=john&age=25"),
  "CONTENT_TYPE" => "application/x-www-form-urlencoded"
})
```

**Standalone (testing):**
When called directly with a hash (typical in unit tests), it returns the given hash as-is.

```ruby
class Show < Hanami::Action
  def handle(request, response)
    # ...
    puts request.params.to_h # => {id: 23, name: "test"}
  end
end

# Direct call with hash for testing
action = Show.new
response = action.call(id: 23, name: "test")
```

#### Declaring allowed params

By default, params represent untrusted input.
For security reasons it's recommended to use hanami-validations to validate the input and remove invalid params.


```ruby
require "hanami/validations"
require "hanami/controller"

class Signup < Hanami::Action
  params do
    required(:first_name).filled(:str?)
    required(:last_name).filled(:str?)
    required(:email).filled(:str?)

    required(:address).schema do
      required(:line_one).filled(:str?)
      required(:state).filled(:str?)
      required(:country).filled(:str?)
    end
  end

  def handle(request, *)
    # :first_name is allowed, but not :admin is not
    puts request.params[:first_name]     # => "Jericho"
    puts request.params[:admin]          # => nil

    # :address's :line_one is allowed, but :line_two is not
    puts request.params[:address][:line_one] # => "123 Motor City Blvd"
    puts request.params[:address][:line_two] # => nil
  end
end

Signup.new.call({first_name: "Jericho", admin: true, address: { line_one: "123 Motor City Blvd" }})
```

#### Validations & Coercions

Because params are a well-defined set of data required to fulfill a request in your application, you can validate them.
In Hanami, we put validations at the action level, since different use-cases require different validation rules.
This also lets us ensure we have well-structured data further into our application.

If you specify the `:type` option, the param will be coerced.

```ruby
require "hanami/validations"
require "hanami/controller"

class Signup < Hanami::Action
  MEGABYTE = 1024 ** 2

  params do
    required(:first_name).filled(:str?)
    required(:last_name).filled(:str?)
    required(:email).filled(:str?, format?: /\A.+@.+\z/)
    required(:password).filled(:str?)
    required(:terms_of_service).filled(:bool?)
    required(:age).filled(:int?, included_in?: 18..99)
    optional(:avatar).filled(size?: 1..(MEGABYTE * 3))
  end

  def handle(request, *)
    halt 400 unless request.params.valid?
    # ...
  end
end

Signup.new.call({}).status # => 400
Signup.new.call({
                    first_name: "Jericho",
                    last_name: "Jackson",
                    email: "actionjackson@example.com",
                    password: "password",
                    terms_of_service: true,
                    age: 40,
                }).status # => 200
```

### Response

The output of `#call` is a `Hanami::Action::Response` (which is a subclass of Rack::Response):

```ruby
class Show < Hanami::Action
end

action = Show.new
action.call({}) # => #<Hanami::Action::Response:0x00007fe8be968418 @status=200 ...>
```

This is the same `response` object passed to `#handle`, where you can use its accessors to explicitly set status, headers, and body:

```ruby
class Show < Hanami::Action
  def handle(request, response)
    response.status  = 201
    response.body    = "Hi!"
    response.headers.merge!("X-Custom" => "OK")
  end
end

action = Show.new
action.call({}) # => [201, { "X-Custom" => "OK", ... }, ["Hi!"]]
```

The Rack API requires response to be an Array with 3 elements: status, headers, and body.
You can call `#to_a` (or `#finish)` on the response to get that Rack representation.

### Exposures

In case you need to send data from the action to other layers of your application, you can use exposures on the response.
By default, an action exposes the request's params and the format.

```ruby
Article = Data.define(:id)

class Show < Hanami::Action
  def handle(request, response)
    response[:article] = Article.new(id: request.params[:id])
  end
end

action   = Show.new
response = action.call(id: 23)

puts response[:article].class # => Article
puts response[:article].id # => 23

response.exposures.keys # => [:article, :params, :format]
```

### Callbacks

If you need to execute logic **before** or **after** `#handle` is invoked, you can use _callbacks_.
They are useful for shared logic like authentication checks.

```ruby
class Show < Hanami::Action
  before :authenticate, :set_article

  def handle(request, response)
  end

  private

  def authenticate
    # ...
  end

  # `request` and `response` in the method signature is optional
  def set_article(request, response)
    response[:article] = ArticleRepo.new.find(request.params[:id])
  end
end
```

Callbacks can also be expressed as anonymous lambdas:

```ruby
class Show < Hanami::Action
  before { ... } # do some authentication stuff
  before { |request, response| response[:article] = ArticleRepo.new.find(request.params[:id]) }

  def handle(request, response)
  end
end
```

### Exceptions management

When the app raises an exception, `hanami-controller`, does **NOT** manage it.
You can write custom exception handling on per action or configuration basis.

An exception handler can be a valid HTTP status code (eg. `500`, `401`), or a `Symbol` that represents an action method.

```ruby
class Show < Hanami::Action
  handle_exception StandardError => 500

  def handle(request, response)
    raise
  end
end

action = Show.new
response = action.call({})
p response.status # => 500
p response.body # => ["Internal Server Error"]
```

You can map a specific raised exception to a different HTTP status.

```ruby
RecordNotFound = Class.new(StandardError)

class Show < Hanami::Action
  handle_exception RecordNotFound => 404

  def handle(request, response)
    raise RecordNotFound
  end
end

action = Show.new
response = action.call({})
p response.status # => 404
p response.body # ["Not Found"]
```

You can also define custom handlers for exceptions.

```ruby
class Create < Hanami::Action
  handle_exception ArgumentError => :my_custom_handler

  def handle(request, response)
    raise ArgumentError.new("Invalid arguments")
  end

  private

  def my_custom_handler(request, response, exception)
    response.status = 400
    response.body   = exception.message
  end
end

action = Create.new
response = action.call({})
p response.status # => 400
p response.body # => ["Invalid arguments"]
```


### Throwable HTTP statuses

When `#halt` is used with a valid HTTP code, it stops the execution and sets the proper status and body for the response:

```ruby
class Show < Hanami::Action
  before :authenticate!

  def handle(request, response)
    # ...
  end

  private

  def authenticate!
    halt 401 unless authenticated?
  end

  def authenticated?
    false # to demonstrate the use of `#halt`
  end
end

action = Show.new
response = action.call({})
p response.status  #=> 401
p response.body # => ["Unauthorized"]
```

Alternatively, you can specify a custom message to be used in the response body:

```ruby
class DroidRepo; def find(id) = nil; end;

class Show < Hanami::Action
  def handle(request, response)
    response[:droid] = DroidRepo.new.find(request.params[:id]) or not_found
  end

  private

  def not_found
    halt 404, "This is not the droid you're looking for"
  end
end

action = Show.new
response = action.call({})
p response.status # => 404
p response.body # => ["This is not the droid you're looking for"]
```

### Cookies

You can read the original cookies sent from the HTTP client via `request.cookies`.
If you want to send cookies in the response, use `response.cookies`.

They are read as a Hash on the request (using String keys), coming from the Rack env:

```ruby
require "hanami/controller"

class ReadCookiesFromRackEnv < Hanami::Action

  def handle(request, response)
    # ...
    puts request.cookies["foo"] # => "bar"
  end
end

action = ReadCookiesFromRackEnv.new
action.call({"HTTP_COOKIE" => "foo=bar"})
```

They are set like a Hash, once `include Hanami::Action::Cookies` is used:

```ruby
require "hanami/controller"

class SetCookies < Hanami::Action
  include Hanami::Action::Cookies

  def handle(request, response)
    # ...
    response.cookies["foo"] = "bar"
  end
end

action = SetCookies.new
action.call({}).headers.fetch("Set-Cookie") # "foo=bar"
```

They are removed by setting their value to `nil`:

```ruby
require "hanami/controller"

class RemoveCookies < Hanami::Action
  include Hanami::Action::Cookies

  def handle(request, response)
    # ...
    response.cookies[:foo] = nil
  end
end

action = RemoveCookies.new
action.call({}).headers.fetch("Set-Cookie") # => "foo=; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 -0000"
```

Default values can be set in configuration, but overridden case by case.

```ruby
require "hanami/controller"

class SetCookies < Hanami::Action
  include Hanami::Action::Cookies

  config.cookies = { max_age: 300 }

  def handle(request, response)
    # ...
    response.cookies[:foo] = { value: "bar" }
    response.cookies[:baz] = { value: "boo", max_age: 100 }
  end
end

action = SetCookies.new
p action.call({}).headers.fetch("Set-Cookie").lines
# => ["foo=bar; max-age=300\n",
#     "baz=boo; max-age=100; expires=Thu, 18 Sep 2025 18:14:18 GMT"]
```

### Sessions

Actions have built-in support for Rack sessions.
Similarly to cookies, you can read the session sent by the HTTP client via `request.session`,
and manipulate it via `response.session`.

```ruby
require "hanami/controller"

class ReadSessionFromRackEnv < Hanami::Action
  include Hanami::Action::Session
    config.session = { expire_after: 3600 }

  def handle(request, *)
    # ...
    puts request.session[:age] # => "35"
  end
end

action = ReadSessionFromRackEnv.new
action.call({ "rack.session" => { "age" => "35" } })
```

Values can be set like a Hash:

```ruby
require "hanami/controller"
require "hanami/action/session"

class SetSession < Hanami::Action
  include Hanami::Action::Session

  def handle(request, response)
    # ...
    response.session[:age] = 31
  end
end

action = SetSession.new
response = action.call({})
response.session # => { age: 31 }
# Also available via response.env["rack.session"]
```

Values can be removed like a Hash:

```ruby
require "hanami/controller"
require "hanami/action/session"

class RemoveSession < Hanami::Action
  include Hanami::Action::Session

  def handle(request, response)
    # ...
    response.session[:age] = nil
  end
end

action = RemoveSession.new
action.call({}).session # => {age: nil}
```

While Hanami::Controller supports sessions natively, it's **session store agnostic**.
You have to specify the session store in your Rack middleware configuration (eg `config.ru`).

```ruby
use Rack::Session::Cookie, secret: SecureRandom.hex(64)
run Show.new
```

### HTTP Cache

Hanami::Controller sets your headers correctly according to [RFC 2616, sec. 14.9](http://tools.ietf.org/html/rfc2616#section-14.9.1).

You can easily set the Cache-Control header for your actions:

```ruby
require "hanami/controller"

class HttpCache < Hanami::Action
  include Hanami::Action::Cache

  cache_control :public, max_age: 600

  def handle(request, response)
    # ...
  end
end

response = HttpCache.new.call({})
puts response.headers.fetch("Cache-Control") # => "public, max-age=600"
```

Expires header can be specified using `expires` method:

```ruby
require "hanami/controller"

class HttpCache < Hanami::Action
  include Hanami::Action::Cache

  expires 600, :public

  def handle(request, response)
    # ...
  end
end

response = HttpCache.new.call({})
p response.headers.fetch("Expires") # => "Thu, 18 Sep 2025 21:30:00 GMT" (600 seconds from `Time.now`)
p response.headers.fetch("Cache-Control") # => "public, max-age=600"
```

### Conditional Get

According to HTTP specification, conditional GETs provide a way for web servers to inform clients that the response to a GET request hasn't change since the last request returning a `304 (Not Modified)` response.

Passing the `HTTP_IF_NONE_MATCH` (content identifier) or `HTTP_IF_MODIFIED_SINCE` (timestamp) headers allows the web server define if the client has a fresh version of a given resource.

You can easily take advantage of Conditional Get using `#fresh` method:

```ruby
require "hanami/controller"
require "hanami/action/cache"

class ConditionalGetController < Hanami::Action
  include Hanami::Action::Cache

  def handle(*)
    # ...
    fresh etag: resource.cache_key
    # => halt 304 with header IfNoneMatch = resource.cache_key
  end
end
```

If `resource.cache_key` is equal to `IfNoneMatch` header, then hanami will `halt 304`.

An alternative to hashing based check, is the time based check:

```ruby
require "hanami/controller"
require "hanami/action/cache"

class ConditionalGetController < Hanami::Action
  include Hanami::Action::Cache

  def handle(*)
    # ...
    fresh last_modified: resource.updated_at
    # => halt 304 with header IfModifiedSince = resource.updated_at.httpdate
  end
end
```

If `resource.updated_at` is equal to `IfModifiedSince` header, then hanami will `halt 304`.

### Redirect

If you need to redirect the client to another resource, use `response.redirect_to`:

```ruby
class Create < Hanami::Action
  def handle(*, response)
    # ...
    response.redirect_to "http://example.com/articles/23"
  end
end

action = Create.new(configuration: configuration)
action.call({ article: { title: "Hello" }}) # => [302, {"Location" => "/articles/23"}, ""]
```

You can also redirect with a custom status code:

```ruby
class Create < Hanami::Action
  def handle(*, response)
    # ...
    response.redirect_to "http://example.com/articles/23", status: 301
  end
end

action = Create.new(configuration: configuration)
action.call({ article: { title: "Hello" }}) # => [301, {"Location" => "/articles/23"}, ""]
```

### MIME Types

`Hanami::Action` automatically sets the `Content-Type` header, according to the request.

```ruby
class Show < Hanami::Action
  def handle(*)
  end
end

action = Show.new(configuration: configuration)

response = action.call({ "HTTP_ACCEPT" => "*/*" }) # Content-Type "application/octet-stream"
response.format                                    # :all

response = action.call({ "HTTP_ACCEPT" => "text/html" }) # Content-Type "text/html"
response.format                                          # :html
```

However, you can force this value:

```ruby
class Show < Hanami::Action
  def handle(*, response)
    # ...
    response.format = :json
  end
end

action = Show.new(configuration: configuration)

response = action.call({ "HTTP_ACCEPT" => "*/*" }) # Content-Type "application/json"
response.format                                    # :json

response = action.call({ "HTTP_ACCEPT" => "text/html" }) # Content-Type "application/json"
response.format                                          # :json
```

You can restrict the accepted MIME types:

```ruby
class Show < Hanami::Action
  accept :html, :json

  def handle(*)
    # ...
  end
end

# When called with "*/*"              => 200
# When called with "text/html"        => 200
# When called with "application/json" => 200
# When called with "application/xml"  => 415
```

You can check if the requested MIME type is accepted by the client.

```ruby
class Show < Hanami::Action
  def handle(request, response)
    # ...
    # request.env["HTTP_ACCEPT"] # => "text/html,application/xhtml+xml,application/xml;q=0.9"

    request.accept?("text/html")        # => true
    request.accept?("application/xml")  # => true
    request.accept?("application/json") # => false
    response.format                     # :html


    # request.env["HTTP_ACCEPT"] # => "*/*"

    request.accept?("text/html")        # => true
    request.accept?("application/xml")  # => true
    request.accept?("application/json") # => true
    response.format                     # :html
  end
end
```

Hanami::Controller is shipped with an extensive list of the most common MIME types.
Also, you can register your own:

```ruby
configuration = Hanami::Controller::Configuration.new do |config|
  config.format custom: "application/custom"
end

class Index < Hanami::Action
  def handle(*)
  end
end

action = Index.new(configuration: configuration)

response = action.call({ "HTTP_ACCEPT" => "application/custom" }) # => Content-Type "application/custom"
response.format                                                   # => :custom

class Show < Hanami::Action
  def handle(*, response)
    # ...
    response.format = :custom
  end
end

action = Show.new(configuration: configuration)

response = action.call({ "HTTP_ACCEPT" => "*/*" }) # => Content-Type "application/custom"
response.format                                    # => :custom
```

### Streamed Responses

When the work to be done by the server takes time, it may be a good idea to stream your response. Here's an example of a streamed CSV.

```ruby
configuration = Hanami::Controller::Configuration.new do |config|
  config.format csv: 'text/csv'
end

class Csv < Hanami::Action
  def handle(*, response)
    response.format = :csv
    response.body = Enumerator.new do |yielder|
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
  class Index < Hanami::Action
    # ...
  end

  class Show < Hanami::Action
    # ...
  end
end

Articles::Index.new(configuration: configuration).call({})
```

### Hanami::Router integration

```ruby
require "hanami/router"
require "hanami/controller"

module Web
  module Controllers
    module Books
      class Show < Hanami::Action
        def handle(*)
        end
      end
    end
  end
end

configuration = Hanami::Controller::Configuration.new
router = Hanami::Router.new(configuration: configuration, namespace: Web::Controllers) do
  get "/books/:id", "books#show"
end
```

### Rack integration

Hanami::Controller is compatible with Rack. If you need to use any Rack middleware, please mount them in `config.ru`.

### Configuration

Hanami::Controller can be configured via `Hanami::Controller::Configuration`.
It supports a few options:

```ruby
require "hanami/controller"

configuration = Hanami::Controller::Configuration.new do |config|
  # If the given exception is raised, return that HTTP status
  # It can be used multiple times
  # Argument: hash, empty by default
  #
  config.handle_exception ArgumentError => 404

  # Register a format to MIME type mapping
  # Argument: hash, key: format symbol, value: MIME type string, empty by default
  #
  config.format custom: "application/custom"

  # Define a default format to set as `Content-Type` header for response,
  # unless otherwise specified.
  # If not defined here, it will return Rack's default: `application/octet-stream`
  # Argument: symbol, it should be already known. defaults to `nil`
  #
  config.default_response_format = :html

  # Define a default charset to return in the `Content-Type` response header
  # If not defined here, it returns `utf-8`
  # Argument: string, defaults to `nil`
  #
  config.default_charset = "koi8-r"
end
```

### Thread safety

An Action is **immutable**, it works without global state, so it's thread-safe by design.

## Versioning

__Hanami::Controller__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright © 2014–2024 Hanami Team – Released under MIT License
