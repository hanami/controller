require 'test_helper'

describe 'Framework freeze' do
  describe 'Hanami::Controller' do
    before do
      Hanami::Controller.load!
    end

    it 'freezes framework configuration' do
      Hanami::Controller.configuration.must_be :frozen?
    end

#     it 'freezes action configuration' do
#       CallAction.configuration.must_be :frozen?
#     end
  end

  describe 'duplicated framework' do
    before do
      MusicPlayer::Controller.load!
    end

    it 'freezes framework configuration' do
      MusicPlayer::Controller.configuration.must_be :frozen?
    end

    # it 'freezes action configuration' do
    #   MusicPlayer::Controllers::Artists::Index.configuration.must_be :frozen?
    # end
  end
end
