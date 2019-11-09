require 'minitest/autorun'
require 'mutant/minitest/coverage'
require 'exponential_backoff'

class ExponentialBackoffTest < Minitest::Test
  cover 'ExponentialBackoff*'

  def test_range_initializer
    backoff = ExponentialBackoff.new(1..5)
    assert_equal [1, 2, 4, 5], backoff.intervals_for(0..3)
  end

  def test_array_initializer
    backoff = ExponentialBackoff.new([1, 5])
    assert_equal [1, 2, 4, 5], backoff.intervals_for(0..3)
  end

  def test_no_maximal_time
    exc = assert_raises ArgumentError do
      ExponentialBackoff.new(2)
    end
    assert_equal "Invalid range specified", exc.message
  end

  def test_multiplier_default
    min, max = 1, 2
    backoff = ExponentialBackoff.new(min, max)

    assert_equal 2, backoff.multiplier
  end

  def test_randomize_factor_default
    min, max = 1, 2
    backoff = ExponentialBackoff.new(min, max)

    assert_equal 0, backoff.randomize_factor
  end

  def test_next_interval
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)

    assert_equal min, backoff.next_interval
    assert_equal 2,   backoff.next_interval
    assert_equal 4,   backoff.next_interval
    assert_equal max, backoff.next_interval
  end

  def test_current_interval
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)

    assert_nil backoff.current_interval
    backoff.next_interval
    assert_equal 1, backoff.current_interval
  end

  def test_clear
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)
    2.times { backoff.next_interval }
    backoff.clear

    assert_equal min, backoff.next_interval
  end

  def test_interval_at
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)

    assert_equal 5, backoff.interval_at(3)
  end

  def test_intervals_for
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)

    assert_equal [2, 4, 5, 5], backoff.intervals_for(1..4)
  end

  def test_intervals_is_enumerator
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)

    assert_kind_of Enumerator, backoff.intervals
  end

  def test_intervals_enumerator_is_independent
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)
    first, second = backoff.intervals, backoff.intervals
    first.next

    refute_equal first.next, second.next
  end

  def test_interval_is_float
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)

    assert_kind_of Float, backoff.next_interval
  end

  def test_multiplier
    min, max = 1, 512
    backoff = ExponentialBackoff.new(min, max)
    backoff.multiplier = 4

    assert_equal [4, 16, 64, 256], backoff.intervals_for(1..4)
  end

  def test_randomize_factor
    min, max = 1, 5
    backoff = ExponentialBackoff.new(min, max)
    backoff.randomize_factor = 0.25

    1_000.times do
      assert_in_delta(0.75, 1.25, backoff.interval_at(0))
      assert_in_delta(3.75, 6.25, backoff.interval_at(100))
    end
  end

  def test_until_success_executor_stops_on_truthiness_return_value
    min, max = 0.1, 0.5
    backoff = ExponentialBackoff.new(min, max)

    counter = 0
    return_true = -> {
      counter += 1
      return true
    }
    backoff.until_success { return_true.call }
    assert_equal 1, counter
  end

  def test_until_success_executor_continues_on_falsy_return_value
    min, max = 0.1, 0.5
    backoff = ExponentialBackoff.new(min, max)

    counter = 0
    return_false = -> {
      counter += 1
      return if counter > 1
      return false
    }
    backoff.until_success { return_false.call }
    assert_equal 2, counter
  end

  def test_until_success_block_params
    min, max = 0.1, 0.5
    backoff = ExponentialBackoff.new(min, max)

    assert_block_params = proc do |interval, iteration|
      assert_equal backoff.interval_at(iteration), interval
    end

    backoff.until_success { |interval, iteration| assert_block_params.call(interval, iteration) }
  end

  def test_until_success_executor_sleep_time
    min, max = 0.1, 0.5
    backoff = ExponentialBackoff.new(min, max)

    counter = 0
    return_false = -> {
      counter += 1
      return if counter > 2
      return false
    }

    time = Time.now.to_f
    backoff.until_success { return_false.call }
    elapsed = Time.now.to_f - time
    assert elapsed >= 0.3
  end

  def test_iteration_active_for_one_from_list
    backoff = ExponentialBackoff.new(1, 10)
    assert backoff.iteration_active?(4)
  end

  def test_iteration_active_for_maximum_interval_multiple
    backoff = ExponentialBackoff.new(1, 10)
    assert backoff.iteration_active?(20)
  end

  def test_iteration_active_for_not_from_list_and_not_multiple
    backoff = ExponentialBackoff.new(1, 10)
    refute backoff.iteration_active?(6)
  end

  def test_with_different_boundary
    min, max = 30, 90
    backoff = ExponentialBackoff.new(min, max)

    assert_equal [30, 60, 90, 90], backoff.intervals_for(0..3)
  end

  def test_invalid_range_of_non_numerics
    exc = assert_raises ArgumentError do
      ExponentialBackoff.new('a'..'z')
    end
    assert_equal "Invalid range specified", exc.message
  end
end

