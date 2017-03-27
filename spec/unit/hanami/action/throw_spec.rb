RSpec.describe Hanami::Action do
  before do
    Hanami::Controller.unload!
  end

  describe '.handle_exception' do
    it 'handle an exception with the given status' do
      response = HandledExceptionAction.new.call({})

      expect(response[0]).to be(404)
    end

    it "returns a 500 if an action isn't handled" do
      response = UnhandledExceptionAction.new.call({})

      expect(response[0]).to be(500)
    end

    describe 'with global handled exceptions' do
      it 'handles raised exception' do
        response = GlobalHandledExceptionAction.new.call({})

        expect(response[0]).to be(400)
      end
    end
  end

  describe '#throw' do
    HTTP_TEST_STATUSES.each do |code, body|
      next if HTTP_TEST_STATUSES_WITHOUT_BODY.include?(code)

      it "throws an HTTP status code: #{code}" do
        response = ThrowCodeAction.new.call(status: code)

        expect(response[0]).to be(code)
        expect(response[2]).to eq([body])
      end
    end

    it "throws an HTTP status code with given message" do
      response = ThrowCodeAction.new.call(status: 401, message: 'Secret Sauce')

      expect(response[0]).to be(401)
      expect(response[2]).to eq(['Secret Sauce'])
    end

    it 'throws the code as it is, when not recognized' do
      response = ThrowCodeAction.new.call(status: 2_131_231)

      expect(response[0]).to be(500)
      expect(response[2]).to eq(['Internal Server Error'])
    end

    it 'stops execution of before filters (method)' do
      response = ThrowBeforeMethodAction.new.call({})

      expect(response[0]).to be(401)
      expect(response[2]).to eq(['Unauthorized'])
    end

    it 'stops execution of before filters (block)' do
      response = ThrowBeforeBlockAction.new.call({})

      expect(response[0]).to be(401)
      expect(response[2]).to eq(['Unauthorized'])
    end

    it 'stops execution of after filters (method)' do
      response = ThrowAfterMethodAction.new.call({})

      expect(response[0]).to be(408)
      expect(response[2]).to eq(['Request Timeout'])
    end

    it 'stops execution of after filters (block)' do
      response = ThrowAfterBlockAction.new.call({})

      expect(response[0]).to be(408)
      expect(response[2]).to eq(['Request Timeout'])
    end
  end

  describe 'using Kernel#throw in an action' do
    it 'should work' do
      response = CatchAndThrowSymbolAction.new.call({})

      expect(response[0]).to be(200)
    end
  end
end
