require 'test_helper'
require 'rack'

describe Lotus::Action::Params do
  it 'is frozen' do
    params = Lotus::Action::Params.new({id: '23'})
    params.must_be :frozen?
  end

  describe 'whitelisting' do
    before do
      @params = Class.new(Lotus::Action::Params)
    end

    it 'accepts both string and symbols as names' do
      @params.param :id
      @params.param 'first_name'

      @params.send(:attributes).keys.must_equal([:id, :first_name])
    end

    describe "when this feature isn't enabled" do
      before do
        @action = ParamsAction.new
      end

      it 'creates a Params innerclass' do
        assert defined?(ParamsAction::Params),
          "expected ParamsAction::Params to be defined"

        assert ParamsAction::Params.ancestors.include?(Lotus::Action::Params),
          "expected ParamsAction::Params to be a Lotus::Action::Params subclass"

        assert !ParamsAction::Params.whitelisting?,
          "expected ParamsAction::Params to not be whitelisted"
      end

      describe "in testing mode" do
        it 'returns all the params as they are' do
          _, _, body = @action.call({a: 1, b: 2, c: 3})
          body.must_equal [%({:a=>1, :b=>2, :c=>3})]
        end
      end

      describe "in a Rack context" do
        it 'returns all the params as they are' do
          response = Rack::MockRequest.new(@action).request('PATCH', "?id=23", params: { x: { foo: 'bar' } })
          response.body.must_match %({:id=>"23", :x=>{:foo=>"bar"}})
        end
      end

      describe "with Lotus::Router" do
        it 'returns all the params as they are' do
          _, _, body = @action.call({ 'router.params' => {id: 23}})
          body.must_equal [%({:id=>23})]
        end
      end
    end

    describe "when this feature is enabled" do
      describe "with an explicit class" do
        before do
          @action = WhitelistedParamsAction.new
        end

        describe "in testing mode" do
          it 'returns only the listed params' do
            _, _, body = @action.call({id: 23, unknown: 4})
            body.must_equal [%({:id=>23})]
          end
        end

        describe "in a Rack context" do
          it 'returns only the listed params' do
            response = Rack::MockRequest.new(@action).request('PATCH', "?id=23", params: { x: { foo: 'bar' } })
            response.body.must_match %({:id=>"23"})
          end
        end

        describe "with Lotus::Router" do
          it 'returns only the listed params' do
            _, _, body = @action.call({ 'router.params' => {id: 23, another: 'x'}})
            body.must_equal [%({:id=>23})]
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

          assert WhitelistedDslAction::Params.ancestors.include?(Lotus::Action::Params),
            "expected WhitelistedDslAction::Params to be a Lotus::Action::Params subclass"

          assert WhitelistedDslAction::Params.whitelisting?,
            "expected WhitelistedDslAction::Params to be whitelisted"
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

        describe "with Lotus::Router" do
          it 'returns only the listed params' do
            _, _, body = @action.call({ 'router.params' => {username: 'jodosha', y: 'x'}})
            body.must_equal [%({:username=>"jodosha"})]
          end
        end
      end
    end
  end

  describe 'validations' do
    before do
      TestParams = Class.new(Lotus::Action::Params) do
        param :email, presence:   true, format: /\A.+@.+\z/
        param :name,  presence:   true
        param :tos,   acceptance: true
      end
    end

    after do
      Object.send(:remove_const, :TestParams)
    end

    it "isn't valid with empty params" do
      params = TestParams.new({})

      params.valid?.must_equal false

      params.errors.for(:email).must_include Lotus::Validations::Error.new(:email, :presence, true, nil)
      params.errors.for(:name).must_include  Lotus::Validations::Error.new(:name, :presence, true, nil)
      params.errors.for(:tos).must_include   Lotus::Validations::Error.new(:tos, :acceptance, true, nil)
    end

    it "is it valid when all the validation criteria are met" do
      params = TestParams.new({email: 'test@lotusrb.org', name: 'Luca', tos: '1'})

      params.valid?.must_equal true
      params.errors.must_be_empty
    end
  end
end
