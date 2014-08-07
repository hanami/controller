require 'test_helper'

describe 'Directives' do
  describe '#directives' do
    describe 'non value directives' do
      it 'accepts public symbol' do
        subject = Lotus::Action::Cache::Directives.new(:public)
        subject.values.size.must_equal(1)
      end

      it 'accepts private symbol' do
        subject = Lotus::Action::Cache::Directives.new(:private)
        subject.values.size.must_equal(1)
      end

      it 'accepts no_cache symbol' do
        subject = Lotus::Action::Cache::Directives.new(:no_cache)
        subject.values.size.must_equal(1)
      end

      it 'accepts no_store symbol' do
        subject = Lotus::Action::Cache::Directives.new(:no_store)
        subject.values.size.must_equal(1)
      end

      it 'accepts no_transform symbol' do
        subject = Lotus::Action::Cache::Directives.new(:no_transform)
        subject.values.size.must_equal(1)
      end

      it 'accepts must_revalidate symbol' do
        subject = Lotus::Action::Cache::Directives.new(:must_revalidate)
        subject.values.size.must_equal(1)
      end

      it 'accepts proxy_revalidate symbol' do
        subject = Lotus::Action::Cache::Directives.new(:proxy_revalidate)
        subject.values.size.must_equal(1)
      end

      it 'does not accept weird symbol' do
        subject = Lotus::Action::Cache::Directives.new(:weird)
        subject.values.size.must_equal(0)
      end

      describe 'multiple symbols' do
        it 'creates one directive for each valid symbol' do
          subject = Lotus::Action::Cache::Directives.new(:private, :proxy_revalidate)
          subject.values.size.must_equal(2)
        end
      end

      describe 'private and public at the same time' do
        it 'ignores public directive' do
          subject = Lotus::Action::Cache::Directives.new(:private, :public)
          subject.values.size.must_equal(1)
        end

        it 'creates one private directive' do
          subject = Lotus::Action::Cache::Directives.new(:private, :public)
          subject.values.first.name.must_equal(:private)
        end
      end
    end

    describe 'value directives' do
      it 'accepts max_age symbol' do
        subject = Lotus::Action::Cache::Directives.new(max_age: 600)
        subject.values.size.must_equal(1)
      end

      it 'accepts s_maxage symbol' do
        subject = Lotus::Action::Cache::Directives.new(s_maxage: 600)
        subject.values.size.must_equal(1)
      end

      it 'accepts min_fresh symbol' do
        subject = Lotus::Action::Cache::Directives.new(min_fresh: 600)
        subject.values.size.must_equal(1)
      end

      it 'accepts max_stale symbol' do
        subject = Lotus::Action::Cache::Directives.new(max_stale: 600)
        subject.values.size.must_equal(1)
      end

      it 'does not accept weird symbol' do
        subject = Lotus::Action::Cache::Directives.new(weird: 600)
        subject.values.size.must_equal(0)
      end

      describe 'multiple symbols' do
        it 'creates one directive for each valid symbol' do
          subject = Lotus::Action::Cache::Directives.new(max_age: 600, max_stale: 600)
          subject.values.size.must_equal(2)
        end
      end
    end

    describe 'value and non value directives' do
      it 'creates one directive for each valid symbol' do
        subject = Lotus::Action::Cache::Directives.new(:public, max_age: 600, max_stale: 600)
        subject.values.size.must_equal(3)
      end
    end
  end
end

describe 'ValueDirective' do
  describe '#to_str' do
    it 'returns as http cache format' do
      subject = Lotus::Action::Cache::ValueDirective.new(:max_age, 600)
      subject.to_str.must_equal('max-age=600')
    end
  end
end

describe 'NonValueDirective' do
  describe '#to_str' do
    it 'returns as http cache format' do
      subject = Lotus::Action::Cache::NonValueDirective.new(:no_cache)
      subject.to_str.must_equal('no-cache')
    end
  end
end
