# Lotus::Controller

A Rack compatible Controller layer for [Lotus](http://lotusrb.org).

## Status

[![Gem Version](https://badge.fury.io/rb/lotus-controller.png)](http://badge.fury.io/rb/lotus-controller)
[![Build Status](https://secure.travis-ci.org/lotus/controller.png?branch=master)](http://travis-ci.org/lotus/controller?branch=master)
[![Coverage](https://coveralls.io/repos/lotus/controller/badge.png?branch=master)](https://coveralls.io/r/lotus/controller)
[![Code Climate](https://codeclimate.com/github/lotus/controller.png)](https://codeclimate.com/github/lotus/controller)
[![Dependencies](https://gemnasium.com/lotus/controller.png)](https://gemnasium.com/lotus/controller)

## Contact

* Home page: http://lotusrb.org
* Mailing List: http://lotusrb.org/mailing-list
* API Doc: http://rdoc.info/gems/lotus-controller
* Bugs/Issues: https://github.com/lotus/controller/issues
* Support: http://stackoverflow.com/questions/tagged/lotusrb

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

Lotus::Controller is a thin layer (**230 LOCs**) for MVC web frameworks.
It works beautifully with [Lotus::Router](https://github.com/lotus/router), but it can be employed everywhere.
It's designed with performances and testability in mind.

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

An action is an object after all, it's important that you have the full control on it.
In other words, you have the freedom of instantiate, inject dependencies and test it, both with unit and integration.

In the example below, we're stating that the default repository is `Article`, but during an unit test we can inject a stubbed version, and invoke `#call` with the params that we want to simulate.
We're avoiding HTTP calls, we're eventually avoiding to hit the database (it depends on the stubbed repository), we're just dealing with message passing.
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

action = Show.new(StubArticleRepository)
action.call({ id: 23 })
```

### Params

The request params are passed as an argument to the `#call` method.
If routed with *Lotus::Router*, it extracts the relevant bits from the Rack `env`.
Otherwise everything it's passed as it is: the full Rack `env` in production, and the given `Hash` for unit tests.

```ruby
action   = Show.new
response = action.call({ id: 23 })

assert_equal 200, response[0]
```

### Exposures

We know that actions are objects and Lotus::Action respects one of the pillars of OOP: __encapsulation__.
Other frameworks extract instance variables (`@ivar`) and make them available to the view context.
The solution of Lotus::Action is a simple and powerful DSL: `expose`.
It's a thin layer on top of `attr_reader`. When used, it creates a getter for the given attribute, and adds it to the _exposures_.
Exposures (`#exposures`) is set of exposed attributes, so that the view context can have the information needed to render a page.

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

### Response

The output of `#call` is a serialized Rack::Response (see [#finish](http://rack.rubyforge.org/doc/classes/Rack/Response.html#M000182)):

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
action.call({}) # => [500, {}, [""]]
```

### Throwable HTTP statuses

When [#throw](http://ruby-doc.org/core-2.1.0/Kernel.html#method-i-throw) is used with a valid HTTP code, it stops the execution and sets the proper status and body for the response:

```ruby
class Show
  include Lotus::Action

  before :authenticate!

  def call(params)
    # ...
  end

  private
  def authenticate!
    throw 401 unless authenticated?
  end
end

action = Show.new
action.call({}) # => [401, {}, ["Unauthorized"]]
```

### Cookies

It offers convenient access to cookies.

They are read as an Hash from Rack env:

```ruby
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

They are set like an Hash:

```ruby
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

Values can be set like an Hash:

```ruby
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

Values can be removed like an Hash:

```ruby
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
use Rack::Session::Cookie, secret: SecureRandom.hex(16)
run Show.new
```

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

### Mime types

Lotus::Action automatically sets the mime type, according to the request headers.
However, you can override this value:

```ruby
class Show
  include Lotus::Action

  def call(params)
    # ...
    self.content_type = 'application/json'
  end
end

action = Show.new
action.call({ id: 23 }) # => [200, {'Content-Type' => 'application/json'}, '...']
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

Which is a bit verboses. Instead, just do:

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

## Lotus::Router integration

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

## Rack integration

Lotus::Controller is compatible with Rack. However, it doesn't mount any middleware.
While a Lotus application's architecture is more web oriented, this framework is designed to be a pure HTTP entpoint.

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
