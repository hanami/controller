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

  describe 'exception_code' do
    describe 'when the given error is unknown' do
      it 'returns the default value' do
        @configuration.exception_code(Exception).must_equal 500
      end
    end

    describe 'when the given error was registered' do
      before do
        @configuration.handle_exception NotImplementedError => 400
      end

      it 'returns the default value' do
        @configuration.exception_code(NotImplementedError).must_equal 400
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
      end
    end

    after do
      Object.send(:remove_const, :FakeAction)
      Object.send(:remove_const, :FakeCallable)
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

  describe 'duplicate' do
    before do
      @configuration.reset!
      @configuration.modules { include Kernel }
      @config = @configuration.duplicate
    end

    it 'returns a copy of the configuration' do
      @config.handle_exceptions.must_equal  @configuration.handle_exceptions
      @config.handled_exceptions.must_equal @configuration.handled_exceptions
      @config.action_module.must_equal      @configuration.action_module
      @config.modules.must_equal            @configuration.modules
    end

    it "doesn't affect the original configuration" do
      @config.handle_exceptions = false
      @config.handle_exception ArgumentError => 400
      @config.action_module    CustomAction
      @config.modules          { include Comparable }

      @config.handle_exceptions.must_equal  false
      @config.handled_exceptions.must_equal Hash[ArgumentError => 400]
      @config.action_module.must_equal      CustomAction
      @config.modules.size.must_equal       2

      @configuration.handle_exceptions.must_equal  true
      @configuration.handled_exceptions.must_equal Hash[]
      @configuration.action_module.must_equal      ::Lotus::Action
      @configuration.modules.size.must_equal       1
    end
  end

  describe 'reset!' do
    before do
      @configuration.handle_exceptions = false
      @configuration.handle_exception ArgumentError => 400
      @configuration.action_module    CustomAction
      @configuration.modules          { include Kernel }

      @configuration.reset!
    end

    it 'resets to the defaults' do
      @configuration.handle_exceptions.must_equal(true)
      @configuration.handled_exceptions.must_equal({})
      @configuration.action_module.must_equal(::Lotus::Action)
      @configuration.modules.must_equal([])
    end
  end
end
