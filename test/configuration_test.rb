require 'test_helper'

describe Lotus::Controller::Configuration do
  before do
    @configuration = Lotus::Controller::Configuration.new
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

  describe 'reset!' do
    before do
      @configuration.handle_exceptions = false
      @configuration.handle_exception ArgumentError => 400

      @configuration.reset!
    end

    it 'resets to the defaults' do
      @configuration.handle_exceptions.must_equal(true)
      @configuration.handled_exceptions.must_equal({})
    end
  end
end
