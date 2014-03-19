require 'test_helper'

describe Lotus::Action do
  describe '#call' do
    it 'calls an action' do
      response = CallAction.new.call({})

      response[0].must_equal 201
      response[1].must_equal({'Content-Type' => 'application/octet-stream', 'X-Custom' => 'OK'})
      response[2].must_equal ['Hi from TestAction!']
    end

    it 'returns an HTTP 500 status code when an exception is raised' do
      response = ErrorCallAction.new.call({})

      response[0].must_equal 500
      response[2].must_equal ['Internal Server Error']
    end

    describe 'when exception handling code is disabled' do
      before do
        ErrorCallAction.handle_exceptions = false
      end

      after do
        ErrorCallAction.handle_exceptions = true
      end

      it 'should raise an actual exception' do
        proc {
          ErrorCallAction.new.call({})
        }.must_raise RuntimeError
      end
    end
  end

  describe '#expose' do
    it 'creates a getter for the given ivar' do
      action = ExposeAction.new

      response = action.call({})
      response[0].must_equal 200

      action.exposures.must_equal({ film: '400 ASA', time: nil })
    end
  end
end
