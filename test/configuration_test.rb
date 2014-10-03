require 'test_helper'

describe Lotus::Controller::Configuration do
  before do
    module CustomAction
    end

    @configuration = Lotus::Controller::Configuration.new
  end

  after do
    Object.send(:remove_const, :CustomAction)
  end

  describe 'handle exceptions' do
    it 'returns true by default' do
      @configuration.handle_exceptions.must_equal(true)
    end

    it 'allows to set the value with a writer' do
      @configuration.handle_exceptions = false
      @configuration.handle_exceptions.must_equal(false)
    end

    it 'allows to set the value with a dsl' do
      @configuration.handle_exceptions(false)
      @configuration.handle_exceptions.must_equal(false)
    end

    it 'ignores nil' do
      @configuration.handle_exceptions(nil)
      @configuration.handle_exceptions.must_equal(true)
    end
  end

  describe 'handled exceptions' do
    it 'returns an empty hash by default' do
      @configuration.handled_exceptions.must_equal({})
    end

    it 'allows to set an exception' do
      @configuration.handle_exception ArgumentError => 400
      @configuration.handled_exceptions.must_include(ArgumentError)
    end
  end

  describe 'exception_handler' do
    describe 'when the given error is unknown' do
      it 'returns the default value' do
        @configuration.exception_handler(Exception).must_equal :default_exception_handler
      end
    end

    describe 'when the given error was registered' do
      before do
        @configuration.handle_exception NotImplementedError => :not_found
      end

      it 'returns specified value' do
        @configuration.exception_handler(NotImplementedError.new).must_equal :not_found
      end
    end
  end

  describe 'action_module' do
    describe 'when not previously configured' do
      it 'returns the default value' do
        @configuration.action_module.must_equal(::Lotus::Action)
      end
    end

    describe 'when previously configured' do
      before do
        @configuration.action_module(CustomAction)
      end

      it 'returns the value' do
        @configuration.action_module.must_equal(CustomAction)
      end
    end
  end

  describe 'modules' do
    before do
      class FakeAction
      end unless defined?(FakeAction)

      module FakeCallable
        def call(params)
          [status, {}, ['Callable']]
        end

        def status
          200
        end
      end unless defined?(FakeCallable)

      module FakeStatus
        def status
          318
        end
      end unless defined?(FakeStatus)
    end

    after do
      Object.send(:remove_const, :FakeAction)
      Object.send(:remove_const, :FakeCallable)
      Object.send(:remove_const, :FakeStatus)
    end

    describe 'when not previously configured' do
      it 'is empty' do
        @configuration.modules.must_be_empty
      end
    end

    describe 'when previously configured' do
      before do
        @configuration.modules do
          include FakeCallable
        end
      end

      it 'allows to configure additional modules to include' do
        @configuration.modules do
          include FakeStatus
        end

        @configuration.modules.each do |mod|
          FakeAction.class_eval(&mod)
        end

        code, _, body = FakeAction.new.call({})
        code.must_equal 318
        body.must_equal ['Callable']
      end
    end

    it 'allows to configure modules to include' do
      @configuration.modules do
        include FakeCallable
      end

      @configuration.modules.each do |mod|
        FakeAction.class_eval(&mod)
      end

      code, _, body = FakeAction.new.call({})
      code.must_equal 200
      body.must_equal ['Callable']
    end
  end

  describe '#format' do
    before do
      @configuration.format custom: 'custom/format'

      BaseObject = Class.new(BasicObject) do
        def hash
          23
        end
      end
    end

    after do
      Object.send(:remove_const, :BaseObject)
    end

    it 'registers the given format' do
      @configuration.format_for('custom/format').must_equal :custom
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      -> { @configuration.format(23 => 'boom') }.must_raise TypeError
    end

    it 'raises an error if the given mime type cannot be coerced into string' do
      -> { @configuration.format(boom: BaseObject.new) }.must_raise TypeError
    end
  end

  describe '#default_format' do
    describe "when not previously set" do
      it 'returns nil' do
        @configuration.default_format.must_be_nil
      end
    end

    describe "when set" do
      before do
        @configuration.default_format :html
      end

      it 'returns the value' do
        @configuration.default_format.must_equal :html
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      -> { @configuration.default_format(23) }.must_raise TypeError
    end
  end

  describe '#format_for' do
    it 'returns a symbol from the given mime type' do
      @configuration.format_for('*/*').must_equal                      :all
      @configuration.format_for('application/octet-stream').must_equal :all
      @configuration.format_for('text/html').must_equal                :html
    end

    describe 'with custom defined formats' do
      before do
        @configuration.format htm: 'text/html'
      end

      after do
        @configuration.reset!
      end

      it 'returns the custom defined mime type, which takes the precedence over the builtin value' do
        @configuration.format_for('text/html').must_equal :htm
      end
    end
  end

  describe '#mime_type_for' do
    it 'returns a mime type from the given symbol' do
      @configuration.mime_type_for(:all).must_equal  'application/octet-stream'
      @configuration.mime_type_for(:html).must_equal 'text/html'
    end

    describe 'with custom defined formats' do
      before do
        @configuration.format htm: 'text/html'
      end

      after do
        @configuration.reset!
      end

      it 'returns the custom defined format, which takes the precedence over the builtin value' do
        @configuration.mime_type_for(:htm).must_equal 'text/html'
      end
    end
  end

  describe 'duplicate' do
    before do
      @configuration.reset!
      @configuration.modules { include Kernel }
      @configuration.format custom: 'custom/format'
      @configuration.default_format :html
      @config = @configuration.duplicate
    end

    it 'returns a copy of the configuration' do
      @config.handle_exceptions.must_equal  @configuration.handle_exceptions
      @config.handled_exceptions.must_equal @configuration.handled_exceptions
      @config.action_module.must_equal      @configuration.action_module
      @config.modules.must_equal            @configuration.modules
      @config.send(:formats).must_equal     @configuration.send(:formats)
      @config.default_format.must_equal     @configuration.default_format
    end

    it "doesn't affect the original configuration" do
      @config.handle_exceptions = false
      @config.handle_exception ArgumentError => 400
      @config.action_module    CustomAction
      @config.modules          { include Comparable }
      @config.format another: 'another/format'
      @config.default_format :json

      @config.handle_exceptions.must_equal           false
      @config.handled_exceptions.must_equal          Hash[ArgumentError => 400]
      @config.action_module.must_equal               CustomAction
      @config.modules.size.must_equal                2
      @config.format_for('another/format').must_equal :another
      @config.default_format.must_equal               :json

      @configuration.handle_exceptions.must_equal  true
      @configuration.handled_exceptions.must_equal Hash[]
      @configuration.action_module.must_equal      ::Lotus::Action
      @configuration.modules.size.must_equal       1
      @configuration.format_for('another/format').must_be_nil
      @configuration.default_format.must_equal     :html
    end
  end

  describe 'reset!' do
    before do
      @configuration.handle_exceptions = false
      @configuration.handle_exception ArgumentError => 400
      @configuration.action_module    CustomAction
      @configuration.modules          { include Kernel }
      @configuration.format another: 'another/format'
      @configuration.default_format :another

      @configuration.reset!
    end

    it 'resets to the defaults' do
      @configuration.handle_exceptions.must_equal(true)
      @configuration.handled_exceptions.must_equal({})
      @configuration.action_module.must_equal(::Lotus::Action)
      @configuration.modules.must_equal([])
      @configuration.send(:formats).must_equal(Lotus::Controller::Configuration::DEFAULT_FORMATS)
      @configuration.default_format.must_be_nil
    end
  end
end
