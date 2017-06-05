RSpec.describe "Framework configuration" do
  it "keeps separated copies of the configuration" do
    hanami_configuration = Hanami::Controller.configuration
    music_configuration = MusicPlayer::Controller.configuration
    artists_show_config = MusicPlayer::Controllers::Artists::Show.configuration

    expect(hanami_configuration).to_not eq(music_configuration)
    expect(hanami_configuration).to_not eq(artists_show_config)
  end

  it "inheriths configurations at the framework level" do
    _, _, body = MusicPlayer::Controllers::Dashboard::Index.new.call({})
    expect(body).to eq(["Muzic!"])
  end

  it "catches exception handled at the framework level" do
    code, = MusicPlayer::Controllers::Dashboard::Show.new.call({})
    expect(code).to be(400)
  end

  it "catches exception handled at the action level" do
    code, = MusicPlayer::Controllers::Artists::Show.new.call({})
    expect(code).to be(404)
  end

  it "allows standalone actions to inherith framework configuration" do
    code, = MusicPlayer::StandaloneAction.new.call({})
    expect(code).to be(400)
  end

  it "allows standalone modulized actions to inherith framework configuration" do
    expect(Hanami::Controller.configuration.handled_exceptions).to_not include(App::CustomError)
    expect(App::StandaloneAction.configuration.handled_exceptions).to  include(App::CustomError)

    code, = App::StandaloneAction.new.call({})
    expect(code).to be(400)
  end

  it "allows standalone modulized controllers to inherith framework configuration" do
    expect(Hanami::Controller.configuration.handled_exceptions).to_not  include(App2::CustomError)
    expect(App2::Standalone::Index.configuration.handled_exceptions).to include(App2::CustomError)

    code, = App2::Standalone::Index.new.call({})
    expect(code).to be(400)
  end

  it "includes modules from configuration" do
    modules = MusicPlayer::Controllers::Artists::Show.included_modules
    expect(modules).to include(Hanami::Action::Cookies)
    expect(modules).to include(Hanami::Action::Session)
  end

  it "correctly includes user defined modules" do
    code, _, body = MusicPlayer::Controllers::Artists::Index.new.call({})
    expect(code).to be(200)
    expect(body).to eq(["Luca"])
  end

  describe "default headers" do
    it "if default headers aren't setted only content-type header is returned" do
      code, headers, = FullStack::Controllers::Home::Index.new.call({})
      expect(code).to    be(200)
      expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8")
    end

    it "if default headers are setted, default headers are returned" do
      code, headers, = MusicPlayer::Controllers::Artists::Index.new.call({})
      expect(code).to    be(200)
      expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "X-Frame-Options" => "DENY")
    end

    it "default headers overrided in action" do
      code, headers, = MusicPlayer::Controllers::Dashboard::Index.new.call({})
      expect(code).to    be(200)
      expect(headers).to eq("Content-Type" => "application/octet-stream; charset=utf-8", "X-Frame-Options" => "ALLOW FROM https://example.org")
    end
  end
end
