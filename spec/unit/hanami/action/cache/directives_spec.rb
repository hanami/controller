RSpec.describe 'Directives' do
  describe '#directives' do
    describe 'non value directives' do
      it 'accepts public symbol' do
        subject = Hanami::Action::Cache::Directives.new(:public)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts private symbol' do
        subject = Hanami::Action::Cache::Directives.new(:private)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts no_cache symbol' do
        subject = Hanami::Action::Cache::Directives.new(:no_cache)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts no_store symbol' do
        subject = Hanami::Action::Cache::Directives.new(:no_store)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts no_transform symbol' do
        subject = Hanami::Action::Cache::Directives.new(:no_transform)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts must_revalidate symbol' do
        subject = Hanami::Action::Cache::Directives.new(:must_revalidate)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts proxy_revalidate symbol' do
        subject = Hanami::Action::Cache::Directives.new(:proxy_revalidate)
        expect(subject.values.size).to eq(1)
      end

      it 'does not accept weird symbol' do
        subject = Hanami::Action::Cache::Directives.new(:weird)
        expect(subject.values.size).to eq(0)
      end

      describe 'multiple symbols' do
        it 'creates one directive for each valid symbol' do
          subject = Hanami::Action::Cache::Directives.new(:private, :proxy_revalidate)
          expect(subject.values.size).to eq(2)
        end
      end

      describe 'private and public at the same time' do
        it 'ignores public directive' do
          subject = Hanami::Action::Cache::Directives.new(:private, :public)
          expect(subject.values.size).to eq(1)
        end

        it 'creates one private directive' do
          subject = Hanami::Action::Cache::Directives.new(:private, :public)
          expect(subject.values.first.name).to eq(:private)
        end
      end
    end

    describe 'value directives' do
      it 'accepts max_age symbol' do
        subject = Hanami::Action::Cache::Directives.new(max_age: 600)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts s_maxage symbol' do
        subject = Hanami::Action::Cache::Directives.new(s_maxage: 600)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts min_fresh symbol' do
        subject = Hanami::Action::Cache::Directives.new(min_fresh: 600)
        expect(subject.values.size).to eq(1)
      end

      it 'accepts max_stale symbol' do
        subject = Hanami::Action::Cache::Directives.new(max_stale: 600)
        expect(subject.values.size).to eq(1)
      end

      it 'does not accept weird symbol' do
        subject = Hanami::Action::Cache::Directives.new(weird: 600)
        expect(subject.values.size).to eq(0)
      end

      describe 'multiple symbols' do
        it 'creates one directive for each valid symbol' do
          subject = Hanami::Action::Cache::Directives.new(max_age: 600, max_stale: 600)
          expect(subject.values.size).to eq(2)
        end
      end
    end

    describe 'value and non value directives' do
      it 'creates one directive for each valid symbol' do
        subject = Hanami::Action::Cache::Directives.new(:public, max_age: 600, max_stale: 600)
        expect(subject.values.size).to eq(3)
      end
    end
  end
end

RSpec.describe 'ValueDirective' do
  describe '#to_str' do
    it 'returns as http cache format' do
      subject = Hanami::Action::Cache::ValueDirective.new(:max_age, 600)
      expect(subject.to_str).to eq('max-age=600')
    end
  end
end

RSpec.describe 'NonValueDirective' do
  describe '#to_str' do
    it 'returns as http cache format' do
      subject = Hanami::Action::Cache::NonValueDirective.new(:no_cache)
      expect(subject.to_str).to eq('no-cache')
    end
  end
end
