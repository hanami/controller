require 'test_helper'

describe "Exception notifiers integration" do
  let(:env) { Hash[] }

  it 'reference error in rack.exception' do
    action = RackExceptionAction.new
    action.call(env)

    env['rack.exception'].must_be_kind_of RackExceptionAction::TestException
  end

  it "doesnt' reference error in rack.exception if it's handled" do
    action = HandledRackExceptionAction.new
    action.call(env)

    env['rack.exception'].must_be_nil
  end

  it "doesn't reference  of an error in rack.exception if it's handled" do
    action = HandledRackExceptionSubclassAction.new
    action.call(env)

    env['rack.exception'].must_be_nil
  end
end
