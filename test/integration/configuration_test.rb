require 'test_helper'

describe 'Framework configuration' do
  it 'inheriths configurations at the framework level' do
    _, _, body = MusicPlayer::Controllers::Dashboard::Index.new.call({})
    body.must_equal ['Muzic!']
  end

  it 'catches exception handled at the framework level' do
    code, _, _ = MusicPlayer::Controllers::Dashboard::Show.new.call({})
    code.must_equal 400
  end

  it 'catches exception handled at the action level' do
    code, _, _ = MusicPlayer::Controllers::Artists::Show.new.call({})
    code.must_equal 404
  end
end
