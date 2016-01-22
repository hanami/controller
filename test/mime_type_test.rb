require 'test_helper'

describe Hanami::Action::Mime do
  it 'exposes content_type' do
    action = CallAction.new
    action.call({})
    action.content_type.must_equal 'application/octet-stream'
  end
end
