require 'test_helper'

describe 'Framework configuration' do
  it 'keeps separated copies of the configuration' do
    lotus_configuration = Lotus::Controller.configuration
    music_configuration = MusicPlayer::Controller.configuration
    artists_show_config = MusicPlayer::Controllers::Artists::Show.configuration

    lotus_configuration.wont_equal(music_configuration)
    lotus_configuration.wont_equal(artists_show_config)
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

  it 'allows standalone actions to inherith framework configuration' do
    code, _, _ = MusicPlayer::StandaloneAction.new.call({})
    code.must_equal 400
  end

  it 'allows standalone modulized actions to inherith framework configuration' do
    Lotus::Controller.configuration.handled_exceptions.wont_include     App::CustomError
    App::StandaloneAction.configuration.handled_exceptions.must_include App::CustomError

    code, _, _ = App::StandaloneAction.new.call({})
    code.must_equal 400
  end

  it 'allows standalone modulized controllers to inherith framework configuration' do
    Lotus::Controller.configuration.handled_exceptions.wont_include       App2::CustomError
    App2::Standalone::Index.configuration.handled_exceptions.must_include App2::CustomError

    code, _, _ = App2::Standalone::Index.new.call({})
    code.must_equal 400
  end

  it 'includes modules from configuration' do
    modules = MusicPlayer::Controllers::Artists::Show.included_modules
    modules.must_include(Lotus::Action::Cookies)
    modules.must_include(Lotus::Action::Session)
  end

  it 'correctly includes user defined modules' do
    code, _, body = MusicPlayer::Controllers::Artists::Index.new.call({})
    code.must_equal 200
    body.must_equal ['Luca']
  end
end
