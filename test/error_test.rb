require 'test_helper'

describe Lotus::Controller::Error do
  it 'inherits from ::StandardError' do
    Lotus::Controller::Error.superclass.must_equal StandardError
  end

  it 'is parent to UnknownFormatError' do
    Lotus::Controller::UnknownFormatError.superclass.must_equal Lotus::Controller::Error
  end
end
