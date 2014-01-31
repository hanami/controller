require 'test_helper'

describe Lotus::Action do
  describe 'throw' do
    HTTP_TEST_STATUSES.each do |code, body|
      it "throws an HTTP status code: #{ code }" do
        response = ThrowCodeAction.new.call({ status: code })

        response[0].must_equal  code
        response[2].must_equal [body]
      end
    end

    it 'throws the code as it is, when not recognized' do
      response = ThrowCodeAction.new.call({ status: 2131231 })

      response[0].must_equal 500
      response[2].must_equal ['Internal Server Error']
    end

    it 'stops execution of before filters (method)' do
      response = ThrowBeforeMethodAction.new.call({})

      response[0].must_equal 401
      response[2].must_equal ['Unauthorized']
    end

    it 'stops execution of before filters (block)' do
      response = ThrowBeforeBlockAction.new.call({})

      response[0].must_equal 401
      response[2].must_equal ['Unauthorized']
    end

    it 'stops execution of after filters (method)' do
      response = ThrowAfterMethodAction.new.call({})

      response[0].must_equal 408
      response[2].must_equal ['Request Timeout']
    end

    it 'stops execution of after filters (block)' do
      response = ThrowAfterBlockAction.new.call({})

      response[0].must_equal 408
      response[2].must_equal ['Request Timeout']
    end
  end
end
