require 'test_helper'

describe Hanami::Action::Exposable do
  describe '#expose' do
    it 'creates a getter for the given ivar' do
      action = ExposeAction.new

      response = action.call({})
      response[0].must_equal 200

      action.exposures.fetch(:film).must_equal '400 ASA'
      action.exposures.fetch(:time).must_equal nil
    end

    describe 'when reserved word is used' do
      subject { ExposeReservedWordAction.expose_reserved_word }

      it 'should raise an exception' do
        ->() { subject }.must_raise Hanami::Action::Exposable::Guard::IllegalExposeError
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
        subject.must_include :flash
      end
    end
  end

  describe '#_expose' do
    describe 'when exposuring a reserved word' do
      it 'does not fail' do
        ExposeReservedWordAction.expose_reserved_word(using_internal_method: true)

        action = ExposeReservedWordAction.new
        action.call({})

        action.exposures.must_include :flash
      end
    end
  end
end
