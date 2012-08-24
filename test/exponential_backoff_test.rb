require 'test/unit'
require 'exponential_backoff'

class ExponentialBackoffTest < Test::Unit::TestCase
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

    assert_not_equal first.next, second.next
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
    return_true = proc do
      counter += 1
      true
    end
    backoff.until_success { return_true.call }
    assert_equal 1, counter
  end

  def test_until_success_executor_continues_on_falsy_return_value
    min, max = 0.1, 0.5
    backoff = ExponentialBackoff.new(min, max)

    counter = 0
    return_false = proc do
      counter += 1
      break if counter > 1
      false
    end
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
    return_false = proc do
      counter += 1
      break if counter > 2
      false
    end

    time = Time.now.to_f
    backoff.until_success { return_false.call }
    elapsed = Time.now.to_f - time

    assert elapsed >= 0.3
  end
end

