require 'test_helper'

describe Lotus::Controller::VERSION do
  it 'returns the current version' do
    Lotus::Controller::VERSION.must_equal '0.1.0'
  end
end
