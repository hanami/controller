RSpec.describe Hanami::Controller do
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
      expect(Hanami::Controller.configuration).to be_kind_of(Hanami::Controller::Configuration)
    end

    it 'handles exceptions by default' do
      expect(Hanami::Controller.configuration.handle_exceptions).to be(true)
    end

    it 'inheriths the configuration from the framework' do
      expected = Hanami::Controller.configuration
      actual   = ConfigurationAction.configuration

      expect(actual).to eq(expected)
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

      expect(Hanami::Controller.configuration.handle_exceptions).to be(false)
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

      expect(Hanami::Controller.configuration.handled_exceptions).to include(ArgumentError)
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

      expect(actual.handled_exceptions).to eq(expected.handled_exceptions)
    end

    it 'duplicates a namespace for controllers' do
      expect(defined?(Duplicated::Controllers)).to eq('constant')
    end

    it 'generates a custom namespace for controllers' do
      expect(defined?(DuplicatedCustom::Controllerz)).to eq('constant')
    end

    it 'does not create a custom namespace for controllers' do
      expect(defined?(DuplicatedWithoutNamespace::Controllers)).to be(nil)
    end

    it 'duplicates Action' do
      expect(defined?(Duplicated::Action)).to eq('constant')
    end

    it 'sets action_module' do
      configuration = Duplicated::Controller.configuration
      expect(configuration.action_module).to eq(Duplicated::Action)
    end

    it 'optionally accepts a block to configure the duplicated module' do
      configuration = DuplicatedConfigure::Controller.configuration

      expect(configuration.handled_exceptions).to_not include(ArgumentError)
      expect(configuration.handled_exceptions).to     include(StandardError)
    end
  end
end
