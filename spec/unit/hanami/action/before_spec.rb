RSpec.describe Hanami::Action do
  describe '.before' do
    it 'invokes the method(s) from the given symbol(s) before the action is run' do
      action = BeforeMethodAction.new(configuration: configuration)
      action.call({})

      expect(action.article).to          eq('Bonjour!'.reverse)
      expect(action.logger.join(' ')).to eq('Mr. John Doe')
    end

    it 'invokes the given block before the action is run' do
      action = BeforeBlockAction.new(configuration: configuration)
      action.call({})

      expect(action.article).to eq('Good morning!'.reverse)
    end

    it 'inherits callbacks from superclass' do
      action = SubclassBeforeMethodAction.new(configuration: configuration)
      action.call({})

      expect(action.article).to eq('Bonjour!'.reverse.upcase)
    end

    it 'can optionally have params in method signature' do
      action = ParamsBeforeMethodAction.new(configuration: configuration)
      action.call('bang' => '!')

      expect(action.article).to             eq('Bonjour!!'.reverse)
      expect(action.exposed_params.to_h).to eq(bang: '!')
    end

    it 'yields params when the callback is a block' do
      action   = YieldBeforeBlockAction.new(configuration: configuration)
      response = action.call('twentythree' => '23')

      expect(response[0]).to be(200)
      expect(action.yielded_params.to_h).to eq(twentythree: '23')
    end

    describe 'on error' do
      it 'stops the callbacks execution and returns an HTTP 500 status' do
        action   = ErrorBeforeMethodAction.new(configuration: configuration)
        response = action.call({})

        expect(response[0]).to    be(500)
        expect(action.article).to be(nil)
      end
    end

    describe 'on handled error' do
      it 'stops the callbacks execution and passes the control on exception handling' do
        action   = HandledErrorBeforeMethodAction.new
        response = action.call({})

        expect(response[0]).to    be(404)
        expect(action.article).to be(nil)
      end
    end
  end
end
