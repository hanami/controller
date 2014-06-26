require 'test_helper'
require 'rack'

describe Lotus::Action::Params do
  it 'accepts params from "router.params"' do
    action   = ParamsAction.new
    response = action.call({ 'router.params' => {id: '23'} })

    response[2].must_equal ["{:id=>\"23\"}"]
  end

  it 'accepts params as they are, for testing purposes' do
    action   = ParamsAction.new
    response = action.call({id: '23'})

    response[2].must_equal ["{:id=>\"23\"}"]
  end

  it 'accepts params from "rack.input" as request body' do
    response = Rack::MockRequest.new(ParamsAction.new).request('PATCH', "?id=23", params: { x: { foo: 'bar' } })
    response.body.must_match "{:id=>\"23\", :x=>{:foo=>\"bar\"}}"
  end

  it 'is frozen' do
    params = Lotus::Action::Params.new({id: '23'})
    params.must_be :frozen?
  end
end
