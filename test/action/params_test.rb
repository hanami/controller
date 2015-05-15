require 'test_helper'
require 'rack'

describe Lotus::Action::Params do
  it 'is frozen'

  # This is temporary suspended.
  # We need to get the dependency Lotus::Validations, more stable before to enable this back.
  #
  # it 'is frozen' do
  #   params = Lotus::Action::Params.new({id: '23'})
  #   params.must_be :frozen?
  # end

  describe 'raw params' do
    before do
      @params = Class.new(Lotus::Action::Params)
    end

    describe "when this feature isn't enabled" do
      before do
        @action = ParamsAction.new
      end

      it 'raw gets all params' do
        @action.call({id: 1, unknown: 2})
        @action.params.raw.get(:id).must_equal 1
        @action.params.raw.get(:unknown).must_equal 2
      end
    end

    describe "when this feature is enabled" do
      before do
        @action = WhitelistedParamsAction.new
      end

      it 'raw gets all params' do
        @action.call({id: 1, unknown: 2})
        @action.params.raw.get(:id).must_equal 1
        @action.params.raw.get(:unknown).must_equal 2
      end
    end
  end

  describe 'whitelisting' do
    before do
      @params = Class.new(Lotus::Action::Params)
    end

    it 'accepts both string and symbols as names' do
      @params.param :id
      @params.param 'first_name'

      @params.defined_attributes.must_equal(Set.new(%w(id first_name)))
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
      end

      describe "in testing mode" do
        it 'returns all the params as they are' do
          _, _, body = @action.call({a: 1, b: 2, c: 3})
          body.must_equal [%({"a"=>1, "b"=>2, "c"=>3})]
        end
      end

      describe "in a Rack context" do
        it 'returns all the params as they are' do
          response = Rack::MockRequest.new(@action).request('PATCH', "?id=23", params: { x: { foo: 'bar' } })
          response.body.must_match %({"id"=>"23", "x"=>{"foo"=>"bar"}})
        end
      end

      describe "with Lotus::Router" do
        it 'returns all the params as they are' do
          _, _, body = @action.call({ 'router.params' => {id: 23}})
          body.must_equal [%({"id"=>23})]
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
            body.must_equal [%({"id"=>23})]
          end
        end

        describe "in a Rack context" do
          it 'returns only the listed params' do
            response = Rack::MockRequest.new(@action).request('PATCH', "?id=23", params: { x: { foo: 'bar' } })
            response.body.must_match %({"id"=>"23"})
          end
        end

        describe "with Lotus::Router" do
          it 'returns only the listed params' do
            _, _, body = @action.call({ 'router.params' => {id: 23, another: 'x'}})
            body.must_equal [%({"id"=>23})]
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
        end

        describe "in testing mode" do
          it 'returns only the listed params' do
            _, _, body = @action.call({username: 'jodosha', unknown: 'field'})
            body.must_equal [%({"username"=>"jodosha"})]
          end
        end

        describe "in a Rack context" do
          it 'returns only the listed params' do
            response = Rack::MockRequest.new(@action).request('PATCH', "?username=jodosha", params: { x: { foo: 'bar' } })
            response.body.must_match %({"username"=>"jodosha"})
          end
        end

        describe "with Lotus::Router" do
          it 'returns only the listed params' do
            _, _, body = @action.call({ 'router.params' => {username: 'jodosha', y: 'x'}})
            body.must_equal [%({"username"=>"jodosha"})]
          end
        end
      end
    end
  end

  describe 'validations' do
    it "isn't valid with empty params" do
      params = TestParams.new({})

      params.valid?.must_equal false

      params.errors.for(:email).
        must_include Lotus::Validations::Error.new(:email, :presence, true, nil)
      params.errors.for(:name).
        must_include Lotus::Validations::Error.new(:name, :presence, true, nil)
      params.errors.for(:tos).
        must_include Lotus::Validations::Error.new(:tos, :acceptance, true, nil)
      params.errors.for('address.line_one').
        must_include Lotus::Validations::Error.new('address.line_one', :presence, true, nil)
    end

    it "is it valid when all the validation criteria are met" do
      params = TestParams.new({email: 'test@lotusrb.org', name: 'Luca', tos: '1', address: { line_one: '10 High Street' }})

      params.valid?.must_equal true
      params.errors.must_be_empty
    end

    it "has input available through the hash accessor" do
      params = TestParams.new(name: 'John', age: '1', address: { line_one: '10 High Street' })
      params[:name].must_equal('John')
      params[:age].must_equal(1)
      params[:address][:line_one].must_equal('10 High Street')
    end

    it "has input available as methods" do
      params = TestParams.new(name: 'John', age: '1', address: { line_one: '10 High Street' })
      params.name.must_equal('John')
      params.age.must_equal(1)
      params.address.line_one.must_equal('10 High Street')
    end

    it "has a nested object even when no input for that object was defined" do
      params = TestParams.new({})
      params.address.wont_be_nil
    end

    it "has the correct nested param superclass type" do
      params = TestParams.new({address: { line_one: '123'}})
      params[:address].class.superclass.must_equal(Lotus::Action::Params)
    end

    it "allows nested hash access via symbols" do
      params = TestParams.new(name: 'John', address: { line_one: '10 High Street', deep: { deep_attr: 1 } })
      params[:name].must_equal 'John'
      params[:address][:line_one].must_equal '10 High Street'
      params[:address][:deep][:deep_attr].must_equal '1'
    end
  end

  describe '#get' do
    describe 'with data' do
      before do
        @params = TestParams.new(name: 'John', address: { line_one: '10 High Street', deep: { deep_attr: 1 } })
      end

      it 'returns nil for nil argument' do
        @params.get(nil).must_be_nil
      end

      it 'returns nil for unknown param' do
        @params.get('unknown').must_be_nil
      end

      it 'allows to read top level param' do
        @params.get('name').must_equal 'John'
      end

      it 'allows to read nested param' do
        @params.get('address.line_one').must_equal '10 High Street'
      end

      it 'returns nil for uknown nested param' do
        @params.get('address.unknown').must_be_nil
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
        @params.get('unknown').must_be_nil
      end

      it 'returns nil for top level param' do
        @params.get('name').must_be_nil
      end

      it 'returns nil for nested param' do
        @params.get('address.line_one').must_be_nil
      end

      it 'returns nil for uknown nested param' do
        @params.get('address.unknown').must_be_nil
      end
    end
  end

  describe '#to_h' do
    let(:params) { Lotus::Action::Params.new(id: '23') }

    it "returns an Utils::Hash" do
      params.to_h.must_be_kind_of Lotus::Utils::Hash
    end

    it "returns unfrozen Hash" do
      params.to_h.wont_be :frozen?
    end

    it "prevents informations escape" do
      hash = params.to_h
      hash.merge!({name: 'L'})

      params.to_h.must_equal(Hash['id' => '23'])
    end

    it 'handles nested params' do
      hash = {
        'tutorial' => {
          'instructions' => [
            {'title' => 'foo',  'body' => 'bar'},
            {'title' => 'hoge', 'body' => 'fuga'}
          ]
        }
      }

      actual = Lotus::Action::Params.new(hash).to_h
      actual.must_equal(hash)

      actual.must_be_kind_of(Lotus::Utils::Hash)
      actual.must_be_kind_of(Lotus::Utils::Hash)
      actual['tutorial'].must_be_kind_of(::Hash)
      actual['tutorial']['instructions'].each do |h|
        h.must_be_kind_of(::Hash)
      end
    end
  end

  describe '#to_hash' do
    let(:params) { Lotus::Action::Params.new(id: '23') }

    it "returns an Utils::Hash" do
      params.to_hash.must_be_kind_of Lotus::Utils::Hash
    end

    it "returns unfrozen Hash" do
      params.to_hash.wont_be :frozen?
    end

    it "prevents informations escape" do
      hash = params.to_hash
      hash.merge!({name: 'L'})

      params.to_hash.must_equal(Hash['id' => '23'])
    end

    it 'handles nested params' do
      hash = {
        'tutorial' => {
          'instructions' => [
            {'title' => 'foo',  'body' => 'bar'},
            {'title' => 'hoge', 'body' => 'fuga'}
          ]
        }
      }

      actual = Lotus::Action::Params.new(hash).to_hash
      actual.must_equal(hash)

      actual.must_be_kind_of(Lotus::Utils::Hash)
      actual['tutorial'].must_be_kind_of(::Hash)
      actual['tutorial']['instructions'].each do |h|
        h.must_be_kind_of(::Hash)
      end
    end
  end
end
