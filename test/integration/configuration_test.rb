require 'test_helper'

describe 'Framework configuration' do
  it 'keeps separated copies of the configuration' do
    lotus_configuration = Lotus::Controller.configuration
    music_configuration = MusicPlayer::Controller.configuration

    dashboard_config = MusicPlayer::Controllers::Dashboard.configuration
    artists_config   = MusicPlayer::Controllers::Artists.configuration

    artists_show_config = MusicPlayer::Controllers::Artists::Show.configuration



    lotus_configuration.wont_equal(music_configuration)

    music_configuration.must_equal(dashboard_config)
    music_configuration.must_equal(artists_config)

    artists_config.wont_equal(artists_show_config)
  end

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
