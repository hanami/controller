require 'test_helper'
require 'rack'

describe Lotus::Action do

  it 'accepts an object which describes the parameters' do
    params_class = Class.new
    action_class = anonymous_params_action_class
    action_class.params(params_class)
  end

  it 'remembers the parameter description class' do
    params_class = Class.new
    action_class = anonymous_params_action_class do
      params params_class
    end
    action_class.params_class.must_equal(params_class)
  end

end
