require 'test_helper'

describe Lotus::Action do
  describe '#before' do
    it 'invokes the method(s) from the given symbol(s) before the action is run' do
      action = BeforeMethodAction.new
      action.call({})

      action.article.must_equal 'Bonjour!'.reverse
    end

    it 'invokes the given block before the action is run' do
      action = BeforeBlockAction.new
      action.call({})

      action.article.must_equal 'Good morning!'.reverse
    end

    it 'inherits callbacks from superclass' do
      action = SubclassBeforeMethodAction.new
      action.call({})

      action.article.must_equal 'Bonjour!'.reverse.upcase
    end

    it 'can optionally have params in method signature' do
      action = ParamsBeforeMethodAction.new
      action.call(params = {'bang' => '!'})

      action.article.must_equal 'Bonjour!!'.reverse
      action.exposed_params.to_h.must_equal(params)
    end

    it 'yields params when the callback is a block' do
      action   = YieldBeforeBlockAction.new
      response = action.call(params = { 'twentythree' => '23' })

      response[0].must_equal 200
      action.yielded_params.to_h.must_equal params
    end

    describe 'on error' do
      it 'stops the callbacks execution and returns an HTTP 500 status' do
        action   = ErrorBeforeMethodAction.new
        response = action.call({})

        response[0].must_equal 500
        action.article.must_be_nil
      end
    end
  end

  describe '#after' do
    it 'invokes the method(s) from the given symbol(s) after the action is run' do
      action = AfterMethodAction.new
      action.call({})

      action.egg.must_equal 'gE!g'
    end

    it 'invokes the given block after the action is run' do
      action = AfterBlockAction.new
      action.call({})

      action.egg.must_equal 'Coque'.reverse
    end

    it 'inherits callbacks from superclass' do
      action = SubclassAfterMethodAction.new
      action.call({})

      action.egg.must_equal 'gE!g'.upcase
    end

    it 'can optionally have params in method signature' do
      action = ParamsAfterMethodAction.new
      action.call(question: '?')

      action.egg.must_equal 'gE!g?'
    end

    it 'yields params when the callback is a block' do
      action = YieldAfterBlockAction.new
      action.call(params = { 'fortytwo' => '42' })

      action.meaning_of_life_params.to_h.must_equal params
    end

    describe 'on error' do
      it 'stops the callbacks execution and returns an HTTP 500 status' do
        action   = ErrorAfterMethodAction.new
        response = action.call({})

        response[0].must_equal 500
        action.egg.must_be_nil
      end
    end
  end
end
