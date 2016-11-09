require 'test_helper'
require 'rack'

describe Hanami::Action::Params do
  it 'is frozen'

  # This is temporary suspended.
  # We need to get the dependency Hanami::Validations, more stable before to enable this back.
  #
  # it 'is frozen' do
  #   params = Hanami::Action::Params.new({id: '23'})
  #   params.must_be :frozen?
  # end

  describe 'raw params' do
    before do
      @params = Class.new(Hanami::Action::Params)
    end

    describe "when this feature isn't enabled" do
      before do
        @action = ParamsAction.new
      end

      it 'raw gets all params' do
        File.open('test/assets/multipart-upload.png', 'rb') do |upload|
          @action.call('id' => '1', 'unknown' => '2', 'upload' => upload, '_csrf_token' => '3')

          @action.params[:id].must_equal                            '1'
          @action.params[:unknown].must_equal                       '2'
          FileUtils.cmp(@action.params[:upload], upload).must_equal true
          @action.params[:_csrf_token].must_equal                   '3'

          @action.params.raw.fetch('id').must_equal          '1'
          @action.params.raw.fetch('unknown').must_equal     '2'
          @action.params.raw.fetch('upload').must_equal      upload
          @action.params.raw.fetch('_csrf_token').must_equal '3'
        end
      end
    end

    describe 'when this feature is enabled' do
      before do
        @action = WhitelistedUploadDslAction.new
      end

      it 'raw gets all params' do
        Tempfile.create('multipart-upload') do |upload|
          @action.call('id' => '1', 'unknown' => '2', 'upload' => upload, '_csrf_token' => '3')

          @action.params[:id].must_equal          '1'
          @action.params[:unknown].must_equal     nil
          @action.params[:upload].must_equal      upload
          @action.params[:_csrf_token].must_equal '3'

          @action.params.raw.fetch('id').must_equal          '1'
          @action.params.raw.fetch('unknown').must_equal     '2'
          @action.params.raw.fetch('upload').must_equal       upload
          @action.params.raw.fetch('_csrf_token').must_equal '3'
        end
      end
    end
  end

  describe 'whitelisting' do
    before do
      @params = Class.new(Hanami::Action::Params)
    end

    describe "when this feature isn't enabled" do
      before do
        @action = ParamsAction.new
      end

      it 'creates a Params innerclass' do
        assert defined?(ParamsAction::Params),
               'expected ParamsAction::Params to be defined'

        assert ParamsAction::Params.ancestors.include?(Hanami::Action::Params),
               'expected ParamsAction::Params to be a Hanami::Action::Params subclass'
      end

      describe 'in testing mode' do
        it 'returns all the params as they are' do
          # For unit tests in Hanami projects, developers may want to define
          # params with symbolized keys.
          _, _, body = @action.call(a: '1', b: '2', c: '3')
          body.must_equal [%({:a=>"1", :b=>"2", :c=>"3"})]
        end
      end

      describe 'in a Rack context' do
        it 'returns all the params as they are' do
          # Rack params are always stringified
          response = Rack::MockRequest.new(@action).request('PATCH', '?id=23', params: { 'x' => { 'foo' => 'bar' } })
          response.body.must_match %({:id=>"23", :x=>{:foo=>"bar"}})
        end
      end

      describe 'with Hanami::Router' do
        it 'returns all the params as they are' do
          # Hanami::Router params are always symbolized
          _, _, body = @action.call('router.params' => { id: '23' })
          body.must_equal [%({:id=>"23"})]
        end
      end
    end

    describe 'when this feature is enabled' do
      describe 'with an explicit class' do
        before do
          @action = WhitelistedParamsAction.new
        end

        # For unit tests in Hanami projects, developers may want to define
        # params with symbolized keys.
        describe 'in testing mode' do
          it 'returns only the listed params' do
            _, _, body = @action.call(id: 23, unknown: 4, article: { foo: 'bar', tags: [:cool] })
            body.must_equal [%({:id=>23, :article=>{:tags=>[:cool]}})]
          end

          it "doesn't filter _csrf_token" do
            _, _, body = @action.call(_csrf_token: 'abc')
            body.must_equal [%({:_csrf_token=>"abc"})]
          end
        end

        describe "in a Rack context" do
          it 'returns only the listed params' do
            response = Rack::MockRequest.new(@action).request('PATCH', "?id=23", params: { x: { foo: 'bar' } })
            response.body.must_match %({:id=>"23"})
          end

          it "doesn't filter _csrf_token" do
            response = Rack::MockRequest.new(@action).request('PATCH', "?id=1", params: { _csrf_token: 'def', x: { foo: 'bar' } })
            response.body.must_match %(:_csrf_token=>"def", :id=>"1")
          end
        end

        describe "with Hanami::Router" do
          it 'returns all the params coming from the router, even if NOT whitelisted' do
            _, _, body = @action.call({ 'router.params' => {id: 23, another: 'x'}})
            body.must_equal [%({:id=>23, :another=>"x"})]
          end
        end
      end

      describe "with an anoymous class" do
        before do
          @action = WhitelistedDslAction.new
        end

        it 'creates a Params innerclass' do
          assert defined?(WhitelistedDslAction::Params),
            "expected WhitelistedDslAction::Params to be defined"

          assert WhitelistedDslAction::Params.ancestors.include?(Hanami::Action::Params),
            "expected WhitelistedDslAction::Params to be a Hanami::Action::Params subclass"
        end

        describe "in testing mode" do
          it 'returns only the listed params' do
            _, _, body = @action.call({username: 'jodosha', unknown: 'field'})
            body.must_equal [%({:username=>"jodosha"})]
          end
        end

        describe "in a Rack context" do
          it 'returns only the listed params' do
            response = Rack::MockRequest.new(@action).request('PATCH', "?username=jodosha", params: { x: { foo: 'bar' } })
            response.body.must_match %({:username=>"jodosha"})
          end
        end

        describe "with Hanami::Router" do
          it 'returns all the router params, even if NOT whitelisted' do
            _, _, body = @action.call({ 'router.params' => {username: 'jodosha', y: 'x'}})
            body.must_equal [%({:username=>"jodosha", :y=>"x"})]
          end
        end
      end
    end
  end

  describe 'validations' do
    it "isn't valid with empty params" do
      params = TestParams.new({})

      params.valid?.must_equal false

      params.errors.fetch(:email).must_equal   ['is missing', 'is in invalid format']
      params.errors.fetch(:name).must_equal    ['is missing']
      params.errors.fetch(:tos).must_equal     ['is missing']
      params.errors.fetch(:address).must_equal ['is missing']

      params.error_messages.must_equal ['Email is missing', 'Email is in invalid format', 'Name is missing', 'Tos is missing', 'Age is missing', 'Address is missing']
    end

    it "isn't valid with empty nested params" do
      params = NestedParams.new(signup: {})

      params.valid?.must_equal false

      params.errors.fetch(:signup).fetch(:name).must_equal ['is missing']
      params.error_messages.must_equal ['Name is missing', 'Age is missing', 'Age must be greater than or equal to 18']
    end

    it "is it valid when all the validation criteria are met" do
      params = TestParams.new(email: 'test@hanamirb.org', name: 'Luca', tos: '1', age: '34', address: { line_one: '10 High Street', deep: { deep_attr: 'blue' } })

      params.valid?.must_equal true
      params.errors.must_be_empty
      params.error_messages.must_be_empty
    end

    it "has input available through the hash accessor" do
      params = TestParams.new(name: 'John', age: '1', address: { line_one: '10 High Street' })
      params[:name].must_equal('John')
      params[:age].must_equal(1)
      params[:address][:line_one].must_equal('10 High Street')
    end

    it "allows nested hash access via symbols" do
      params = TestParams.new(name: 'John', address: { line_one: '10 High Street', deep: { deep_attr: 1 } })
      params[:name].must_equal 'John'
      params[:address][:line_one].must_equal '10 High Street'
      params[:address][:deep][:deep_attr].must_equal 1
    end
  end

  describe '#get' do
    describe 'with data' do
      before do
        @params = TestParams.new(
          name: 'John',
          address: { line_one: '10 High Street', deep: { deep_attr: 1 } },
          array: [{ name: 'Lennon' }, { name: 'Wayne' }]
        )
      end

      it 'returns nil for nil argument' do
        @params.get(nil).must_be_nil
      end

      it 'returns nil for unknown param' do
        @params.get(:unknown).must_be_nil
      end

      it 'allows to read top level param' do
        @params.get(:name).must_equal 'John'
      end

      it 'allows to read nested param' do
        @params.get(:address, :line_one).must_equal '10 High Street'
      end

      it 'returns nil for uknown nested param' do
        @params.get(:address, :unknown).must_be_nil
      end

      it 'allows to read datas under arrays' do
        @params.get(:array, 0, :name).must_equal 'Lennon'
        @params.get(:array, 1, :name).must_equal 'Wayne'
      end
    end

    describe 'without data' do
      before do
        @params = TestParams.new({})
      end

      it 'returns nil for nil argument' do
        @params.get(nil).must_be_nil
      end

      it 'returns nil for unknown param' do
        @params.get(:unknown).must_be_nil
      end

      it 'returns nil for top level param' do
        @params.get(:name).must_be_nil
      end

      it 'returns nil for nested param' do
        @params.get(:address, :line_one).must_be_nil
      end

      it 'returns nil for uknown nested param' do
        @params.get(:address, :unknown).must_be_nil
      end
    end
  end

  describe '#to_h' do
    let(:params) { TestParams.new(name: 'Jane') }

    it "returns a ::Hash" do
      params.to_h.must_be_kind_of ::Hash
    end

    it "returns unfrozen Hash" do
      params.to_h.wont_be :frozen?
    end

    it "prevents informations escape"
    # it "prevents informations escape" do
    #   hash = params.to_h
    #   hash.merge!({name: 'L'})

    #   params.to_h.must_equal(Hash['id' => '23'])
    # end

    it 'handles nested params' do
      input = {
        'address' => {
          'deep' => {
            'deep_attr' => 'foo'
          }
        }
      }

      expected = {
        address: {
          deep: {
            deep_attr: 'foo'
          }
        }
      }

      actual = TestParams.new(input).to_h
      actual.must_equal(expected)

      actual.must_be_kind_of(::Hash)
      actual[:address].must_be_kind_of(::Hash)
      actual[:address][:deep].must_be_kind_of(::Hash)
    end

    describe 'when whitelisting' do
      # This is bug 113.
      it 'handles nested params' do
        input = {
          'name' => 'John',
          'age' => 1,
          'address' => {
            'line_one' => '10 High Street',
            'deep' => {
              'deep_attr' => 'hello'
            }
          }
        }

        expected = {
          name: 'John',
          age: 1,
          address: {
            line_one: '10 High Street',
            deep: {
              deep_attr: 'hello'
            }
          }
        }

        actual = TestParams.new(input).to_h
        actual.must_equal(expected)

        actual.must_be_kind_of(::Hash)
        actual[:address].must_be_kind_of(::Hash)
        actual[:address][:deep].must_be_kind_of(::Hash)
      end
    end
  end

  describe '#to_hash' do
    let(:params) { TestParams.new(name: 'Jane') }

    it "returns a ::Hash" do
      params.to_hash.must_be_kind_of ::Hash
    end

    it "returns unfrozen Hash" do
      params.to_hash.wont_be :frozen?
    end

    it "prevents informations escape"
    # it "prevents informations escape" do
    #   hash = params.to_hash
    #   hash.merge!({name: 'L'})

    #   params.to_hash.must_equal(Hash['id' => '23'])
    # end

    it 'handles nested params' do
      input = {
        'address' => {
          'deep' => {
            'deep_attr' => 'foo'
          }
        }
      }

      expected = {
        address: {
          deep: {
            deep_attr: 'foo'
          }
        }
      }

      actual = TestParams.new(input).to_hash
      actual.must_equal(expected)

      actual.must_be_kind_of(::Hash)
      actual[:address].must_be_kind_of(::Hash)
      actual[:address][:deep].must_be_kind_of(::Hash)
    end

    describe 'when whitelisting' do
      # This is bug 113.
      it 'handles nested params' do
        input = {
          'name' => 'John',
          'age' => 1,
          'address' => {
            'line_one' => '10 High Street',
            'deep' => {
              'deep_attr' => 'hello'
            }
          }
        }

        expected = {
          name: 'John',
          age: 1,
          address: {
            line_one: '10 High Street',
            deep: {
              deep_attr: 'hello'
            }
          }
        }

        actual = TestParams.new(input).to_hash
        actual.must_equal(expected)

        actual.must_be_kind_of(::Hash)
        actual[:address].must_be_kind_of(::Hash)
        actual[:address][:deep].must_be_kind_of(::Hash)
      end

      it 'does not stringify values' do
        input = { 'name' => 123 }
        params = TestParams.new(input)
        params[:name].must_equal(123)
      end
    end
  end
end
