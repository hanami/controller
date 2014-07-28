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

  it 'accepts a parameter description' do
    Lotus::Action::Params.must_respond_to :param
  end

  it 'returns all params when the params are undescribed' do
    action   = anonymous_params_action_class.new
    response = action.call({id: '23', email: 'foo@example.com'})

    response[2].must_equal ["{:id=>\"23\", :email=>\"foo@example.com\"}"]
  end

  it 'passes through only whitelisted params when params are described' do
    params_class = Class.new(Lotus::Action::Params) do
      param :id
    end

    action_class = anonymous_params_action_class do
      params params_class
    end

    action   = action_class.new
    response = action.call({id: '23', email: 'foo@example.com'})

    response[2].must_equal ["{:id=>\"23\"}"]
  end

end
