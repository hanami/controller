RSpec.describe "Framework freeze" do
  describe "Hanami::Controller" do
    before do
      Hanami::Controller.load!
    end

    after do
      Hanami::Controller.unload!
    end

    it "freezes framework configuration" do
      expect(Hanami::Controller.configuration).to be_frozen
    end

    xit "freezes action configuration" do
      expect(CallAction.configuration).to be_frozen
    end
  end

  describe "duplicated framework" do
    before do
      MusicPlayer::Controller.load!
    end

    it "freezes framework configuration" do
      expect(MusicPlayer::Controller.configuration).to be_frozen
    end

    xit "freezes action configuration" do
      expect(MusicPlayer::Controllers::Artists::Index.configuration).to be_frozen
    end
  end
end
