require 'test_helper'

describe Hanami::Controller do
  describe '.included' do
    it 'exposes class configuration' do
      ConfigurationTest.configuration.must_be_kind_of(Hanami::Controller::Configuration)
    end

    it 'handles exceptions by default' do
      ConfigurationTest.configuration.handle_exceptions.must_equal(true)
    end

    it 'inheriths the configuration from the framework' do
      expected = ConfigurationTest.configuration
      actual   = ConfigurationTest::ConfigurationAction.configuration

      actual.must_equal(expected)
    end
  end

  describe '.configure' do
    it 'allows to configure settings' do
      ConfigurationTest.configuration.default_charset.must_equal('utf-8')
    end
  end
end
