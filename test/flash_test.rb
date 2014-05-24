require 'test_helper'
require 'lotus/action/flash'

describe Lotus::Action do
  describe 'flash' do
    let(:flash) { FlashTest.new.get_flash }

    it 'sets the flash' do
      flash[:notice] = 'test'
      flash.now.must_equal({notice: 'test'})
    end

    it 'gets from the flash' do
      flash[:notice] = 'test'
      flash[:notice].must_equal('test')
    end

    it 'the flash is emptied when the value is retrieved' do
      FlashTest.new.get_flash[:notice] = 'test'
      FlashTest.new.get_flash[:notice].must_equal 'test'
      FlashTest.new.get_flash[:notice].must_be_nil
    end

    it 'saves the value of a flash key in the flash instance cachce' do
      flash[:notice] = 'test'
      flash[:notice].must_equal 'test'
      flash[:notice].must_equal 'test'
    end

    it '#has?' do
      flash[:notice] = 'test'
      flash.has?(:notice).must_equal true
      flash.has?(:nokey).must_equal false
    end

    it '#keys' do
      flash[:notice] = 'test'
      flash.keys.must_equal [:notice]
    end

    it '#now' do
      flash[:notice] = 'test'
      flash.now.must_equal({notice: 'test'})
    end
  end
end

