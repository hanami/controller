require 'test_helper'

describe Hanami::Controller do
  describe '.configuration' do
    before do
      Hanami::Controller.unload!

      module ConfigurationAction
        include Hanami::Action
      end
    end

    after do
      Object.send(:remove_const, :ConfigurationAction)
    end

    it 'exposes class configuration' do
      Hanami::Controller.configuration.must_be_kind_of(Hanami::Controller::Configuration)
    end

    it 'handles exceptions by default' do
      Hanami::Controller.configuration.handle_exceptions.must_equal(true)
    end

    it 'inheriths the configuration from the framework' do
      expected = Hanami::Controller.configuration
      actual   = ConfigurationAction.configuration

      actual.must_equal(expected)
    end
  end

  describe '.configure' do
    before do
      Hanami::Controller.unload!
    end

    after do
      Hanami::Controller.unload!
    end

    it 'allows to configure the framework' do
      Hanami::Controller.class_eval do
        configure do
          handle_exceptions false
        end
      end

      Hanami::Controller.configuration.handle_exceptions.must_equal(false)
    end

    it 'allows to override one value' do
      Hanami::Controller.class_eval do
        configure do
          handle_exception ArgumentError => 400
        end

        configure do
          handle_exception NotImplementedError => 418
        end
      end

      Hanami::Controller.configuration.handled_exceptions.must_include(ArgumentError)
    end
  end

  describe '.duplicate' do
    before do
      Hanami::Controller.configure { handle_exception ArgumentError => 400 }

      module Duplicated
        Controller = Hanami::Controller.duplicate(self)
      end

      module DuplicatedCustom
        Controller = Hanami::Controller.duplicate(self, 'Controllerz')
      end

      module DuplicatedWithoutNamespace
        Controller = Hanami::Controller.duplicate(self, nil)
      end

      module DuplicatedConfigure
        Controller = Hanami::Controller.duplicate(self) do
          reset!
          handle_exception StandardError => 400
        end
      end
    end

    after do
      Hanami::Controller.unload!

      Object.send(:remove_const, :Duplicated)
      Object.send(:remove_const, :DuplicatedCustom)
      Object.send(:remove_const, :DuplicatedWithoutNamespace)
      Object.send(:remove_const, :DuplicatedConfigure)
    end

    it 'duplicates the configuration of the framework' do
      actual   = Duplicated::Controller.configuration
      expected = Hanami::Controller.configuration

      actual.handled_exceptions.must_equal expected.handled_exceptions
    end

    it 'duplicates a namespace for controllers' do
      assert defined?(Duplicated::Controllers), 'Duplicated::Controllers expected'
    end

    it 'generates a custom namespace for controllers' do
      assert defined?(DuplicatedCustom::Controllerz), 'DuplicatedCustom::Controllerz expected'
    end

    it 'does not create a custom namespace for controllers' do
      assert !defined?(DuplicatedWithoutNamespace::Controllers), "DuplicatedWithoutNamespace::Controllers wasn't expected"
    end

    it 'duplicates Action' do
      assert defined?(Duplicated::Action), 'Duplicated::Action expected'
    end

    it 'sets action_module' do
      configuration = Duplicated::Controller.configuration
      configuration.action_module.must_equal Duplicated::Action
    end

    it 'optionally accepts a block to configure the duplicated module' do
      configuration = DuplicatedConfigure::Controller.configuration

      configuration.handled_exceptions.wont_include(ArgumentError)
      configuration.handled_exceptions.must_include(StandardError)
    end
  end
end
