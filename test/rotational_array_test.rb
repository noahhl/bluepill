require 'test_helper'

class RotationalArrayTest < Test::Unit::TestCase

  test "array grows to capacity and then evicts earliest members" do
    a = Bluepill::Util::RotationalArray.new(5)
    5.times {|i| a.push i }
    assert_equal 5, a.length
    assert a.include?(0)
    a << 6
    assert_equal a.last, 6
    assert_equal 5, a.length
    assert !a.include?(0)
  end

end