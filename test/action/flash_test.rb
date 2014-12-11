require 'test_helper'

describe Lotus::Action::Flash do
  let (:flash) { Lotus::Action::Flash.new({},12312) }

  it '#each returns Enumerable' do
    assert_kind_of Enumerator, flash.each
  end

  describe 'iteration' do

    it '#each yields all flashes to the block' do
      flash[:success], flash[:error] = 'Success', 'Error'
      accum = []
      flash.each { |k, v| accum << { :"#{k}".to_sym =>  v} }
      assert_equal accum, [{success: 'Success'}, {error: 'Error'}]
    end

    after { flash.clear }
  end
end
