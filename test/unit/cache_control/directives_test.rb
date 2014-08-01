require 'test_helper'

describe 'Directives' do
  describe '#directives' do
    describe "non value directives" do
      it 'accepts public symbol' do
        subject = Lotus::Action::CacheControl::Directives.new(:public)
        subject.directives.size.must_equal(1)
      end

      it 'accepts private symbol' do
        subject = Lotus::Action::CacheControl::Directives.new(:private)
        subject.directives.size.must_equal(1)
      end

      it 'accepts no_cache symbol' do
        subject = Lotus::Action::CacheControl::Directives.new(:no_cache)
        subject.directives.size.must_equal(1)
      end

      it 'accepts no_store symbol' do
        subject = Lotus::Action::CacheControl::Directives.new(:no_store)
        subject.directives.size.must_equal(1)
      end

      it 'accepts no_transform symbol' do
        subject = Lotus::Action::CacheControl::Directives.new(:no_transform)
        subject.directives.size.must_equal(1)
      end

      it 'accepts must_revalidate symbol' do
        subject = Lotus::Action::CacheControl::Directives.new(:must_revalidate)
        subject.directives.size.must_equal(1)
      end

      it 'accepts proxy_revalidate symbol' do
        subject = Lotus::Action::CacheControl::Directives.new(:proxy_revalidate)
        subject.directives.size.must_equal(1)
      end

      it "does not accept weird symbol" do
        subject = Lotus::Action::CacheControl::Directives.new(:weird)
        subject.directives.size.must_equal(0)
      end
    end
  end
end
