require 'test_helper'

describe Lotus::Utils::ClassAttribute do
  it 'sets the given value' do
    ClassAttributeTest.callbacks.must_equal([:a])
  end

  it 'the value it is inherited by subclasses' do
    SubclassAttributeTest.callbacks.must_equal([:a])
  end

  it 'if the superclass value changes it does not affects subclasses' do
    ClassAttributeTest.functions = [:y]
    SubclassAttributeTest.functions.must_equal([:x, :y])
  end

  it 'if the subclass value changes it does not affects superclass' do
    SubclassAttributeTest.values = [3,2]
    ClassAttributeTest.values.must_equal([1])
  end
end
