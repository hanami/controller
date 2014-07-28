require 'test_helper'
require 'rack'

describe Lotus::Action::Params do
  it 'is frozen' do
    params = Lotus::Action::Params.new({id: '23'})
    params.must_be :frozen?
  end

  describe 'whitelisting' do
    describe "when this feature isn't enabled" do
      before do
        @action = ParamsAction.new
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
  end
end
