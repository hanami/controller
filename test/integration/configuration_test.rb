require 'test_helper'

describe 'Framework configuration' do
  it 'keeps separated copies of the configuration' do
    music_configuration = MusicPlayer::Controllers.configuration
    artists_show_config = MusicPlayer::Controllers::Artists::Show.configuration

    music_configuration.wont_equal(artists_show_config)
  end

  it 'inheriths configurations at the controllers module level' do
    _, _, body = MusicPlayer::Controllers::Dashboard::Index.new.call({})
    body.must_equal ['Muzic!']
  end

  it 'catches exception handled at the controllers module level' do
    code, _, _ = MusicPlayer::Controllers::Dashboard::Show.new.call({})
    code.must_equal 400
  end

  it 'catches exception handled at the action level' do
    code, _, _ = MusicPlayer::Controllers::Artists::Show.new.call({})
    code.must_equal 404
  end

  it 'allows standalone modulized actions to inherith framework configuration' do
    App::StandaloneAction.configuration.handled_exceptions.must_include App::CustomError

    code, _, _ = App::StandaloneAction.new.call({})
    code.must_equal 400
  end

  it 'allows standalone modulized controllers to inherith framework configuration' do
    App2::Standalone::Index.configuration.handled_exceptions.must_include App2::CustomError

    code, _, _ = App2::Standalone::Index.new.call({})
    code.must_equal 400
  end

  it 'includes modules from configuration' do
    modules = MusicPlayer::Controllers::Artists::Show.included_modules
    modules.must_include(Hanami::Action::Cookies)
    modules.must_include(Hanami::Action::Session)
  end

  it 'correctly includes user defined modules' do
    code, _, body = MusicPlayer::Controllers::Artists::Index.new.call({})
    code.must_equal 200
    body.must_equal ['Luca']
  end

  describe 'default headers' do
    it "if default headers aren't setted only content-type header is returned" do
      code, headers, _ = FullStack::Controllers::Home::Index.new.call({})
      code.must_equal 200
      headers.must_equal({"Content-Type"=>"application/octet-stream; charset=utf-8"})
    end

    it "if default headers are setted, default headers are returned" do
      code, headers, _ = MusicPlayer::Controllers::Artists::Index.new.call({})
      code.must_equal 200
      headers.must_equal({"Content-Type" => "application/octet-stream; charset=utf-8", "X-Frame-Options" => "DENY"})
    end

    it "default headers overrided in action" do
      code, headers, _ = MusicPlayer::Controllers::Dashboard::Index.new.call({})
      code.must_equal 200
      headers.must_equal({"Content-Type" => "application/octet-stream; charset=utf-8", "X-Frame-Options" => "ALLOW FROM https://example.org"})
    end
  end
end
