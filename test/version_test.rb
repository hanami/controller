require 'test_helper'

describe Hanami::Controller::VERSION do
  it 'returns the current version' do
    Hanami::Controller::VERSION.must_equal '1.0.0.rc1'
  end
end
