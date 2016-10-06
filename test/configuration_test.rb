require 'test_helper'

describe Hanami::Controller::Configuration do
  before do
    module CustomAction
    end

    @configuration = Hanami::Controller::Configuration
  end

  after do
    Object.send(:remove_const, :CustomAction)
  end

  describe 'handle exceptions' do
    it 'returns true by default' do
      @configuration.new.handle_exceptions.must_equal(true)
    end

    it 'allows to set the value with a writer' do
      config = @configuration.new do |c|
        c.handle_exceptions = false
      end

      config.handle_exceptions.must_equal(false)
    end
  end

  describe 'handled exceptions' do
    it 'returns an empty hash by default' do
      @configuration.new.handled_exceptions.must_equal({})
    end

    it 'allows to set an exception' do
      config = @configuration.new do |c|
        c.handle_exception ArgumentError => 400
      end

      config.handled_exceptions.must_include(ArgumentError)
    end
  end

  describe 'exception_handler' do
    describe 'when the given error is unknown' do
      it 'returns the default value' do
        @configuration.new.exception_handler(Exception).must_equal 500
      end
    end

    describe 'when the given error was registered' do
      it 'returns configured value when an exception instance is given' do
        config = @configuration.new do |c|
          c.handle_exception NotImplementedError => 400
        end

        config.exception_handler(NotImplementedError.new).must_equal 400
      end
    end
  end

  describe 'action_module' do
    describe 'when not previously configured' do
      it 'returns the default value' do
        @configuration.new.action_module.must_equal(::Hanami::Action)
      end
    end

    describe 'when previously configured' do
      it 'returns the value' do
        config = @configuration.new do |c|
          c.action_module = CustomAction
        end

        config.action_module.must_equal(CustomAction)
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
        @configuration.new.modules.must_be_empty
      end
    end

    describe 'when prepare with no block' do
      it 'raises error' do
        exception = -> { @configuration.new.prepare }.must_raise(ArgumentError)
        exception.message.must_equal 'Please provide a block'
      end
    end

    describe 'when previously configured' do
      before do
        @config = @configuration.new do |c|
          c.prepare do
            include FakeCallable
          end
        end
      end

      it 'allows to configure additional modules to include' do
        config = @config.prepare do
          include FakeStatus
        end

        config.modules.each do |mod|
          FakeAction.class_eval(&mod)
        end

        code, _, body = FakeAction.new.call({})
        code.must_equal 318
        body.must_equal ['Callable']
      end
    end

    it 'allows to configure modules to include' do
      config = @configuration.new.prepare do
        include FakeCallable
      end

      config.modules.each do |mod|
        FakeAction.class_eval(&mod)
      end

      code, _, body = FakeAction.new.call({})
      code.must_equal 200
      body.must_equal ['Callable']
    end
  end

  describe '#format' do
    before do
      @config = @configuration.new do |c|
        c.format custom: 'custom/format'
      end

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
      @config.format_for('custom/format').must_equal :custom
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      lambda do
        @configuration.new do |c|
          c.format(23 => 'boom')
        end
      end.must_raise TypeError
    end

    it 'raises an error if the given mime type cannot be coerced into string' do
      lambda do
        @configuration.new do |c|
          c.format(boom: BaseObject.new)
        end
      end.must_raise TypeError
    end
  end

  describe '#default_request_format' do
    describe "when not previously set" do
      it 'returns nil' do
        @configuration.new.default_request_format.must_be_nil
      end
    end

    describe "when set" do
      it 'returns the value' do
        config = @configuration.new do |c|
          c.default_request_format = :html
        end

        config.default_request_format.must_equal :html
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      lambda do
        @configuration.new do |c|
          c.default_request_format = 23
        end
      end.must_raise TypeError
    end
  end

  describe '#default_response_format' do
    describe "when not previously set" do
      it 'returns nil' do
        @configuration.new.default_response_format.must_be_nil
      end
    end

    describe "when set" do
      it 'returns the value' do
        config = @configuration.new do |c|
          c.default_response_format = :json
        end

        config.default_response_format.must_equal :json
      end
    end

    it 'raises an error if the given format cannot be coerced into symbol' do
      lambda do
        @configuration.new do |c|
          c.default_response_format = 23
        end
      end.must_raise TypeError
    end
  end

  describe '#default_charset' do
    describe "when not previously set" do
      it 'returns nil' do
        @configuration.new.default_charset.must_be_nil
      end
    end

    describe "when set" do
      it 'returns the value' do
        config = @configuration.new do |c|
          c.default_charset = 'latin1'
        end

        config.default_charset.must_equal 'latin1'
      end
    end
  end

  describe '#format_for' do
    it 'returns a symbol from the given mime type' do
      config = @configuration.new

      config.format_for('*/*').must_equal                      :all
      config.format_for('application/octet-stream').must_equal :all
      config.format_for('text/html').must_equal                :html
    end

    describe 'with custom defined formats' do
      it 'returns the custom defined mime type, which takes the precedence over the builtin value' do
        config = @configuration.new do |c|
          c.format htm: 'text/html'
        end

        config.format_for('text/html').must_equal :htm
      end
    end
  end

  describe '#mime_type_for' do
    it 'returns a mime type from the given symbol' do
      config = @configuration.new

      config.mime_type_for(:all).must_equal  'application/octet-stream'
      config.mime_type_for(:html).must_equal 'text/html'
    end

    describe 'with custom defined formats' do
      before do
      end

      it 'returns the custom defined format, which takes the precedence over the builtin value' do
        config = @configuration.new do |c|
          c.format htm: 'text/html'
        end

        config.mime_type_for(:htm).must_equal 'text/html'
      end
    end
  end

  describe '#default_headers' do
    describe "when not previously set" do
      it 'returns default value' do
        @configuration.new.default_headers.must_equal({})
      end
    end

    describe "when set" do
      let(:headers) { {'X-Frame-Options' => 'DENY'} }

      before do
        @config = @configuration.new do |c|
          c.default_headers(headers)
        end
      end

      it 'returns the value' do
        @config.default_headers.must_equal headers
      end

      describe "multiple times" do
        before do
          config      = @config.default_headers(headers)
          @new_config =  config.default_headers('X-Foo' => 'BAR')
        end

        it 'returns the value' do
          @new_config.default_headers.must_equal({
            'X-Frame-Options' => 'DENY',
            'X-Foo'           => 'BAR'
          })
        end
      end

      describe "with nil values" do
        before do
          config      = @config.default_headers(headers)
          @new_config =  config.default_headers('X-NIL' => nil)
        end

        it 'rejects those' do
          @new_config.default_headers.must_equal headers
        end
      end
    end
  end
end
