# Lotus::Controller

A Rack compatible Controller layer for Lotus

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

Lotus::Controller is a thin layer for MVC web frameworks and works beautifully with [Lotus::Router](https://lotusrb.org/router).
It's designed with performances and testability in mind.

### Actions

```ruby
class Show
  include Lotus::Action

  expose :article

  def call(params)
    @article = Article.find params[:id]
  end
end
```

Just include `Lotus::Action`, implement `#call(params)` and you're done: it doesn't interfer with classes inheritance, and leaves all the freedom to **you**, the developer, to control it.
For instance, you can implement your own initialization strategy and eventually inject dependencies while testing:

```ruby
class Show
  include Lotus::Action

  expose :article

  def initialize(repository = Article)
    @repository = repository
  end

  def call(params)
    @article = @repository.find params[:id]
  end
end

action = Show.new(StubArticleRepository)
action.call({ id: 23 })

# or

class Resource
  include Lotus::Action

  expose :article

  def initialize(repository = Article)
    @repository = repository
  end

  def call(params)
    @article = @repository.find params[:id]
  end
end

class Show < Resource
end

class Edit < Resource
end
```

The request params are passed as an argument to the `#call` method: if routed with *Lotus::Router*, it extract the relevant bits from the Rack env, otherwise everything it's passed as it is.
This avoids complex testing scenarios, where real HTTP calls are involved. Imagine a simple test like this:

```ruby
action   = Show.new
response = action.call({ id: 23 })

assert_equal 200, response[0]
```

It has a simple and powerful DSL for attributes: when use the `expose` macro, all the exposed objects are available from the outside:

```ruby
action = Show.new
action.call({ id: 23 })

assert_equal 23, action.article.id

puts action.exposures # => { article: <Article:0x007f965c1d0318 @id=23> }
```

It offers powerful, inheritable callbacks which are executed before and after your `#call` method invocation:

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

The output of `#call` is a serialized Rack response:

```ruby
class Show
  include Lotus::Action

  def call(params)
  end
end

action = Show.new
action.call({}) # => [200, {}, [""]]

class Show
  include Lotus::Action

  def call(params)
    self.status  = 201
    self.headers = { 'X-Custom' => 'OK' }
    self.body    = 'Hi!'
  end
end

action = Show.new
action.call({}) # => [201, { "X-Custom" => "OK" }, ["Hi!"]]

class Show
  include Lotus::Action

  def call(params)
    raise
  end
end

action = Show.new
action.call({}) # => [500, {}, [""]]
```

It has builtin support for Rack sessions

```ruby
class Show
  include Lotus::Action

  def call(params)
  end
end

action = Show.new
action.call({ 'rack.session' => { 'age' => '31' }})

puts action.session # => { 'age' => '31' }
```

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
