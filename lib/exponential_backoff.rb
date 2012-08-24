require 'exponential_backoff/version'

class ExponentialBackoff
  attr_accessor :multiplier, :randomize_factor
  attr_reader   :current_interval

  def initialize(minimal_interval, maximum_elapsed_time)
    @maximum_elapsed_time = maximum_elapsed_time
    @minimal_interval = minimal_interval
    @randomize_factor = 0
    @multiplier = 2.0
    clear
  end

  def clear
    @enumerator = intervals
  end

  def next_interval
    @current_interval = @enumerator.next
  end

  def intervals_for(range)
    range.to_a.map { |iteration| interval_at(iteration) }
  end

  def interval_at(iteration)
    randomized_interval(capped_interval(regular_interval(@minimal_interval, @multiplier, iteration)))
  end

  def intervals
    Enumerator.new do |yielder|
      iteration = 0
      loop do
        yielder.yield interval_at(iteration)
        iteration += 1
      end
    end
  end

  def until_success(&block)
    intervals.each_with_index do |interval, iteration|
      break if block.call(interval, iteration)
      sleep(interval)
    end
  end

  protected

  def regular_interval(initial, multiplier, iteration)
    initial * multiplier ** iteration
  end

  def randomized_interval(interval)
    return interval if @randomize_factor == 0
    min = (1 - @randomize_factor) * interval
    max = (1 + @randomize_factor) * interval
    rand(max - min) + min
  end

  def capped_interval(interval)
    [@maximum_elapsed_time, interval].min
  end
end

