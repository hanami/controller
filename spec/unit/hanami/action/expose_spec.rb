RSpec.describe Hanami::Action do
  describe '.expose' do
    it 'creates a getter for the given ivar' do
      action = ExposeAction.new

      response = action.call({})
      expect(response[0]).to be(200)

      expect(action.exposures.fetch(:film)).to eq('400 ASA')
      expect(action.exposures.fetch(:time)).to be(nil)
    end

    describe 'when reserved word is used' do
      subject { ExposeReservedWordAction.expose_reserved_word }

      it 'should raise an exception' do
        expect { subject }.to raise_error(Hanami::Controller::IllegalExposureError)
      end
    end

    describe 'when reserved word is not used' do
      let(:action_class) do
        Class.new do
          include Hanami::Action

          include Module.new { def flash; end }

          expose :flash
        end
      end

      subject { action_class.new.exposures }

      it 'adds a key to exposures list' do
        expect(subject).to include(:flash)
      end
    end
  end

  describe '#_expose' do
    describe 'when exposuring a reserved word' do
      it 'does not fail' do
        ExposeReservedWordAction.expose_reserved_word(using_internal_method: true)

        action = ExposeReservedWordAction.new
        action.call({})

        expect(action.exposures).to include(:flash)
      end
    end
  end
end
