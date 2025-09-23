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
require "hanami/controller"

class HelloWorld < Hanami::Action
  def handle(request, response)
    response.body = "Hello World!"
  end
end

response = HelloWorld.new.call({})
p response.body # => ["Hello World!"]
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
class ShowArticle < Hanami::Action
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

action = ShowArticle.new(repo: ArticleRepo.new)
action.call(id: 23)
```

### Params

The request params are part of the request passed as an argument to the `#handle` method.

There are three scenarios for how params are extracted:

**With Hanami::Router:**
When routed with *Hanami::Router*, it extracts and merges route parameters, query string parameters, and form parameters (with router params taking precedence).

```ruby
require "hanami/controller"

class InspectParams < Hanami::Action
  def handle(request, response)
    # ...
    p request.params.to_h # => {id: 23, name: "john", age: "25"}
  end
end

# When called via router with route "/users/:id" and query string "?name=john&age=25"
InspectParams.new.call({
  "router.params" => {id: 23},
  "QUERY_STRING" => "name=john&age=25"
})
```

**With Rack environment:**
When used in a Rack application (but without Hanami::Router), it extracts query string and form parameters from the request.

```ruby
require "hanami/controller"

class ParamsFromRackInput < Hanami::Action
  def handle(request, response)
    # ...
    p request.params.to_h # => {name: "john", age: "25"} from query/form
  end
end

# When called with Rack env containing rack.input
ParamsFromRackInput.new.call({
  "rack.input" => StringIO.new("name=john&age=25"),
  "CONTENT_TYPE" => "application/x-www-form-urlencoded"
})
```

**Standalone (testing):**
When called directly with a hash (typical in unit tests), it returns the given hash as-is.

```ruby
require "hanami/controller"

class ParamsFromHash < Hanami::Action
  def handle(request, response)
    # ...
    p request.params.to_h # => {id: 23, name: "test"}
  end
end

# Direct call with hash for testing
action = ParamsFromHash.new
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
    p request.params[:first_name]     # => "Action"
    p request.params[:admin]          # => nil

    # :address's :line_one is allowed, but :line_two is not
    p request.params[:address][:line_one] # => "123 Motor City Blvd"
    p request.params[:address][:line_two] # => nil
  end
end

Signup.new.call({first_name: "Action", admin: true, address: { line_one: "123 Motor City Blvd" }})
```

#### Validations & Coercions

Because params are a well-defined set of data required to fulfill a request in your application, you can validate them.
In Hanami, we put validations at the action level, since different use-cases require different validation rules.
This also lets us ensure we have well-structured data further into our application.

If you specify the `:type` option, the param will be coerced.

```ruby
require "hanami/validations"
require "hanami/controller"

class SignupValidateParams < Hanami::Action
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

SignupValidateParams.new.call({}).status # => 400
SignupValidateParams.new.call({
  first_name: "Action",
  last_name: "Jackson",
  email: "actionjackson@example.com",
  password: "password",
  terms_of_service: true,
  age: 40,
}).status # => 200
```

### Response

The output of `#call` is a `Hanami::Action::Response` (which is a subclass of [Rack::Response](https://github.com/rack/rack/blob/main/lib/rack/response.rb)):

```ruby
require "hanami/controller"

class ReturnsResponse < Hanami::Action
end

action = ReturnsResponse.new
action.call({}).class # => Hanami::Action::Response
```

This is the same `response` object passed to `#handle`, where you can use its accessors to explicitly set status, headers, and body:

```ruby
class ManipulateResponse < Hanami::Action
  def handle(request, response)
    response.status  = 201
    response.body    = "Hi!"
    response.headers.merge!("X-Custom" => "OK")
  end
end

action = ManipulateResponse.new
action.call({}) # => [201, { "X-Custom" => "OK", ... }, ["Hi!"]]
```

The Rack API requires response to be an Array with 3 elements: status, headers, and body.
You can call `#to_a` (or `#finish)` on the response to get that Rack representation.

### Exposures

In case you need to send data from the action to other layers of your application, you can use exposures on the response.
By default, an action exposes the request's params and the format.

```ruby
Article = Data.define(:id)

class ExposeArticle < Hanami::Action
  def handle(request, response)
    response[:article] = Article.new(id: request.params[:id])
  end
end

response = ExposeArticle.new.call(id: 23)

p response[:article].class # => Article
p response[:article].id # => 23

p response.exposures.keys # => [:article, :params, :format]
```

### Callbacks

If you need to execute logic **before** or **after** `#handle` is invoked, you can use _callbacks_.
They are useful for shared logic like authentication checks.

```ruby
require "hanami/controller"

Article = Data.define(:title)
class ArticleRepo; def find(id) = Article.new(title: "Why Hanami? Reason ##{id}"); end

Data.define(:title)
class BeforeCallbackMethodName < Hanami::Action
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

response = BeforeCallbackMethodName.new.call({id: 1000})

p response[:article].title # => "Why Hanami? Reason #1000"
```

Callbacks can also be expressed as anonymous lambdas:

```ruby
require "hanami/controller"

Article = Data.define(:title)
class ArticleRepo; def find(id) = Article.new(title: "Why Hanami? Reason ##{id}"); end

class BeforeCallbackLambda < Hanami::Action
  before { } # do some authentication stuff
  before { |request, response| response[:article] = ArticleRepo.new.find(request.params[:id]) }

  def handle(request, response)
    p "Article: #{response[:article].title}"
  end
end

response = BeforeCallbackLambda.new.call({id: 1001})
p response[:article].title # => "Why Hanami? Reason #1001"
```

### Exceptions management

When the app raises an exception, `hanami-controller`, does **NOT** manage it.
You can write custom exception handling on per action or configuration basis.

An exception handler can be a valid HTTP status code (eg. `500`, `401`), or a `Symbol` that represents an action method.

```ruby
require "hanami/controller"

class HandleStandardError < Hanami::Action
  handle_exception StandardError => 500

  def handle(request, response)
    raise
  end
end

action = HandleStandardError.new
response = action.call({})
p response.status # => 500
p response.body # => ["Internal Server Error"]
```

You can map a specific raised exception to a different HTTP status.

```ruby
require "hanami/controller"

class RecordNotFound < StandardError; end

class HandleCustomException < Hanami::Action
  handle_exception RecordNotFound => 404

  def handle(request, response)
    raise RecordNotFound
  end
end

action = HandleCustomException.new
response = action.call({})
p response.status # => 404
p response.body # ["Not Found"]
```

You can also define custom handlers for exceptions.

```ruby
require "hanami/controller"

class CustomHandler < Hanami::Action
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

action = CustomHandler.new
response = action.call({})
p response.status # => 400
p response.body # => ["Invalid arguments"]
```


### Throwable HTTP statuses

When `#halt` is used with a valid HTTP code, it stops the execution and sets the proper status and body for the response:

```ruby
require "hanami/controller"

class ThrowUnauthorized < Hanami::Action
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

action = ThrowUnauthorized.new
response = action.call({})
p response.status  #=> 401
p response.body # => ["Unauthorized"]
```

Alternatively, you can specify a custom message to be used in the response body:

```ruby
require "hanami/controller"

class DroidRepo; def find(id) = nil; end;

class FindDroid < Hanami::Action
  def handle(request, response)
    response[:droid] = DroidRepo.new.find(request.params[:id]) or not_found
  end

  private

  def not_found
    halt 404, "This is not the droid you're looking for"
  end
end

response = FindDroid.new.call({})
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
    p request.cookies["foo"] # => "bar"
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
    p request.session[:age] # => "35"
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
p response.headers.fetch("Cache-Control") # => "public, max-age=600"
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

According to the HTTP specification,
a conditional GET allows a client to ask a server to send a representation of the data only if it has changed.
If the resource hasn’t changed,
the server responds with *304 Not Modified*;
otherwise, it returns the full representation with *200 OK*.

Passing the 'If-None-Match' header (with ETag content identifier)
or 'If-Modified-Since' header (with a timestamp) headers
allows the server to determine whether the client already has a fresh copy of the resource.
Note that they way to use them in Rack is via the `"HTTP_IF_NONE_MATCH"` and `"HTTP_IF_MODIFIED_SINCE"` env keys on the request.

You can easily take advantage of Conditional Get using `#fresh` method.

```ruby
require "hanami/controller"
require "hanami/action/cache"

Resource = Data.define(:cache_key)

class ConditionalGetEtag < Hanami::Action
  include Hanami::Action::Cache

  def handle(request, response)
    # ...
    resource = Resource.new(cache_key: "abc123")
    response.fresh(etag: resource.cache_key)
    # => `halt 304` when value of header 'If-None-Match' is same as the `etag:` value
  end
end

first_response = ConditionalGetEtag.new.call({})
p first_response.status # => 200

second_response = ConditionalGetEtag.new.call({"HTTP_IF_NONE_MATCH" => "abc123"})
p second_response.status # => 304
```

An alternative to hash-based freshness check, is a time-based check with 'If-Modified-Since'.
If the resource hasn’t been modified since the time specified in the `If-Modified-Since` header,
the server responds with *304 Not Modified*.

```ruby
require "hanami/controller"
require "hanami/action/cache"

Resource = Data.define(:updated_at)

class ConditionalGetTime < Hanami::Action
  include Hanami::Action::Cache

  def handle(request, response)
    # ...
    resource = Resource.new(updated_at: Time.now - 60) # i.e. last updated 1 minute ago
    response.fresh(last_modified: resource.updated_at)
    # => `halt 304` when value of header 'If-Modified-Since' is after the `last_modified:` value
  end
end

first_response = ConditionalGetTime.new.call({})
p first_response.status # => 200

second_response = ConditionalGetTime.new.call({"HTTP_IF_MODIFIED_SINCE" => Time.now.httpdate})
p second_response.status # => 304
```


### Redirect

If you need to redirect the client to another resource, use `response.redirect_to`:

```ruby
require "hanami/controller"

class RedirectAction < Hanami::Action
  def handle(request, response)
    # ...
    response.redirect_to "http://example.com/articles/23"
  end
end

response = RedirectAction.new.call({})
p response.status # => 302
p response.location # => "http://example.com/articles/23" (same as `response.headers["Location"]`)
```

You can also redirect with a custom status code:

```ruby
require "hanami/controller"

class PermanentRedirectAction < Hanami::Action
  def handle(request, response)
    # ...
    response.redirect_to "/articles/23", status: 301
  end
end

response = PermanentRedirectAction.new.call({})
p response.status # => 301
p response.location # => "/articles/23"
```

### MIME Types

`Hanami::Action` automatically sets the `Content-Type` header, according to the request.

```ruby
require "hanami/controller"

class ResponseFormatAction < Hanami::Action
  def handle(request, response)
  end
end

action = ResponseFormatAction.new

first_response = action.call({ "HTTP_ACCEPT" => "*/*" })
p first_response.format        # :all
p first_response.content_type  # "application/octet-stream; charset=utf-8"

second_response = action.call({ "HTTP_ACCEPT" => "text/html" })
p second_response.format       # :html
p second_response.content_type # "text/html; charset=utf-8"
```

However, you can force this value:

```ruby
require "hanami/controller"

class ForcedFormatAction < Hanami::Action
  def handle(request, response)
    # ...
    response.format = :json
  end
end

action = ForcedFormatAction.new

first_response = action.call({ "HTTP_ACCEPT" => "*/*" })
p first_response.format       # :json
p first_response.content_type # "application/json; charset=utf-8"

second_response = action.call({ "HTTP_ACCEPT" => "text/html" })
p second_response.format       # :json
p second_response.content_type # "application/json; charset=utf-8"
```

You can restrict the accepted MIME types:

```ruby
require "hanami/controller"

class RestrictedTypesActionShow < Hanami::Action
  format :html, :json

  def handle(request, response)
    # ...
  end
end


action = RestrictedTypesActionShow.new

any_format_response = action.call({ "HTTP_ACCEPT" => "*/*" })
p any_format_response.status # => 200
p any_format_response.format # :html (since it was listed first)

html_response = action.call({ "HTTP_ACCEPT" => "text/html" })
p html_response.status # => 200
p html_response.format # :html

json_response = action.call({ "HTTP_ACCEPT" => "application/json" })
p json_response.status # => 200
p json_response.format # :json

xml_response = action.call({ "HTTP_ACCEPT" => "application/xml" })
p xml_response.status # => 406 (Not Acceptable)

```

You can check if the requested MIME type is accepted by the client.

```ruby
require "hanami/controller"

class CheckAcceptsAction < Hanami::Action
  def handle(request, response)
    # ...
    # request.env["HTTP_ACCEPT"] # => "text/html,application/xhtml+xml,application/xml;q=0.9"

    p "Accepts header:           #{request.env["HTTP_ACCEPT"]}"
    p "Accepts text/html?        #{request.accept?("text/html")}"
    p "Accepts application/xml?  #{request.accept?("application/xml")}"
    p "Accepts application/json? #{request.accept?("application/json")}"
    p "Response format:          #{response.format.inspect}"
    p
  end
end

action = CheckAcceptsAction.new

action.call({ "HTTP_ACCEPT" => "text/html" })
action.call({ "HTTP_ACCEPT" => "text/html,application/xhtml+xml,application/xml;q=0.9" })
action.call({ "HTTP_ACCEPT" => "application/json" })
action.call({ "HTTP_ACCEPT" => "*/*" })
```

#### Custom Formats

Hanami::Controller ships with an extensive list of the most common MIME types.
You can also register your own:

```ruby
require "hanami/controller"

class CustomFormatAcceptAction < Hanami::Action
  config.formats.add :custom, "application/custom"

  def handle(*)
  end
end

action = CustomFormatAcceptAction.new

response = action.call({ "HTTP_ACCEPT" => "application/custom" })
p response.format        # => :custom
p response.content_type  # => "application/custom; charset=utf-8"
```


You can also manually set the format on the response:

```ruby
require "hanami/controller"

class ManualFormatAction < Hanami::Action
  config.formats.add :custom, "application/custom"

  def handle(request, response)
    # ...
    response.format = :custom
  end
end

action = ManualFormatAction.new

response = action.call({ "HTTP_ACCEPT" => "*/*" })
p response.format       # => :custom
p response.content_type # => "application/custom; charset=utf-8"
```

### No rendering, please

Hanami::Controller is designed to be a pure HTTP endpoint, rendering belongs to the View layer.
You can set the body directly (see [response](#response)), use [Hanami::View](https://github.com/hanami/view).

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

Articles::Index.new().call({})
```

### Rack integration

Hanami::Controller is compatible with Rack. If you need to use any Rack middleware, please mount them in `config.ru`.

### Configuration

Hanami::Action can be configured via `config` on the action class.
It supports the following options:

```ruby
require "hanami/controller"

class MyAction < Hanami::Action
  # If the given exception is raised, return that HTTP status
  # It can be used multiple times
  # Argument: hash, empty by default
  #
  config.handle_exception ArgumentError => 400

  # Register custom formats with MIME type mappings
  # Use formats.add to register new format/MIME type pairs
  #
  config.formats.add :custom, "application/custom"

  # Set accepted formats for this action
  # Argument: format symbols, defaults to all formats
  #
  config.format :html, :json

  # Define a default charset to return in the `Content-Type` response header
  # If not defined here, it returns `utf-8`
  # Argument: string, defaults to `nil`
  #
  config.default_charset = "koi8-r"

  # Set default headers for all responses
  # Argument: hash, empty by default
  #
  config.default_headers = {"X-Frame-Options" => "DENY"}

  # Set default cookie options for all responses
  # Argument: hash, empty by default
  #
  config.cookies = {
    domain: "hanamirb.org",
    path: "/controller",
    secure: true,
    httponly: true
  }

  # Set the root directory for the action (for file downloads)
  # Defaults to current working directory
  # Argument: string path
  #
  config.root_directory = "/path/to/root"

  # Set the public directory path (relative to root directory)
  # Used for file downloads, defaults to "public"
  # Argument: string path
  #
  config.public_directory = "assets"
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
