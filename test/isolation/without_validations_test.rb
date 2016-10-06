require 'rubygems'
require 'bundler'
Bundler.require(:default)

require 'minitest/autorun'
$LOAD_PATH.unshift 'lib'
require 'hanami/controller'

describe 'Without validations' do
  it "doesn't load Hanami::Validations" do
    assert !defined?(Hanami::Validations), 'Expected Hanami::Validations to NOT be defined'
  end

  it "doesn't load Hanami::Action::Validatable" do
    assert !defined?(Hanami::Action::Validatable), 'Expected Hanami::Action::Validatable to NOT be defined'
  end

  it "doesn't load Hanami::Action::Params" do
    assert !defined?(Hanami::Action::Params), 'Expected Hanami::Action::Params to NOT be defined'
  end

  it "doesn't have params DSL" do
    exception = lambda do
      Class.new do
        include Hanami::Action

        params do
          required(:id).filled
        end
      end
    end.must_raise NoMethodError

    exception.message.must_match "undefined method `params' for"
  end

  it "has params that don't respond to .valid?" do
    action = Class.new do
      include Hanami::Action

      def call(params)
        self.body = [params.respond_to?(:valid?), params.valid?]
      end
    end

    _, _, body = action.new.call({})
    body.must_equal [true, true]
  end

  it "has params that don't respond to .errors" do
    action = Class.new do
      include Hanami::Action

      def call(params)
        self.body = params.respond_to?(:errors)
      end
    end

    _, _, body = action.new.call({})
    body.must_equal [false]
  end
end
