require 'exponential_backoff/version'

class ExponentialBackoff
  attr_accessor :multiplier, :randomize_factor
  attr_reader   :current_interval

  def initialize(interval, maximum_elapsed_time = nil)
    if interval.respond_to?(:first)
      @minimal_interval, @maximum_elapsed_time = interval.first, interval.last
    else
      @minimal_interval, @maximum_elapsed_time = interval, maximum_elapsed_time
    end
    verify_correct_range

    @randomize_factor = 0
    @multiplier       = 2.0
    clear
  end

  def clear
    @enumerator = intervals
  end

  def next_interval
    @current_interval = @enumerator.next
  end

  def iteration_active?(iteration)
    index = 0
    current_interval = interval_at(index)
    while current_interval < iteration && current_interval < @maximum_elapsed_time
      index += 1
      current_interval = interval_at(index)
    end
    current_interval == iteration || iteration % @maximum_elapsed_time == 0
  end

  def intervals_for(range)
    range.map { |iteration| interval_at(iteration) }
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
      retval = block.call(interval, iteration)
      return if retval || retval.nil?
      sleep(interval)
    end
  end

  protected

  def verify_correct_range
    raise ArgumentError, "Invalid range specified" if [@minimal_interval, @maximum_elapsed_time].any? { |i| !i.is_a?(Numeric) }
  end

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

