require 'test_helper'

describe 'Method visibility' do
  before do
    @action = VisibilityAction.new
  end

  it 'x' do
    status, headers, body = @action.call({})

    status.must_equal                    201

    headers.fetch('X-Custom').must_equal 'OK'
    headers.fetch('Y-Custom').must_equal 'YO'

    body.must_equal                      ['x']
  end
end
