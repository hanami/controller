require 'test_helper'

describe Hanami::Controller::Error do
  it 'inherits from ::StandardError' do
    Hanami::Controller::Error.superclass.must_equal StandardError
  end

  it 'is parent to UnknownFormatError' do
    Hanami::Controller::UnknownFormatError.superclass.must_equal Hanami::Controller::Error
  end
end
