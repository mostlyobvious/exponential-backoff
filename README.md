Exponential Backoff
===================

[![Build Status](https://secure.travis-ci.org/pawelpacana/exponential-backoff.png)](http://travis-ci.org/pawelpacana/exponential-backoff)

Too lazy to make retries to external services in a fashion that providers recommend? Never heard of [exponential backoff](http://en.wikipedia.org/wiki/Exponential_backoff) technique? Now there is no excuse not to be nice.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem 'exponential-backoff'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install exponential-backoff
```

Usage
-----

Start with specifying minimal and maximal intervals, that is `4s` and `60s` respectively:

```ruby
minimal_interval = 4.0
maximal_elapsed_time = 60.0

backoff = ExponentialBackoff.new(minimal_interval, maximal_elapsed_time)
```

You can get intervals for specified range:

```ruby
backoff.intervals_for(0..5) # [4.0, 8.0, 16.0, 32.0, 60.0, 60.0]
```

Enumerate on them:

```ruby
backoff.intervals.each do |interval|
  sleep(interval)
end
```

Or just get interval for requested, that is 3rd, iteration:

```ruby
backoff.interval_at(3) # 32.0
```

Intervals don't exceed maximal allowed time:

```ruby
backoff.interval_at(20) # 60.0
```

Backoff instance maintains state, you can ask for next interval...

```ruby
backoff.next_interval # 4.0
backoff.next_interval # 8.0
```

...and reset it to start from beginning

```ruby
backoff.clear
backoff.next_interval # 4.0
```

Finally you can specify interval multiplier and randomization factor:

```ruby
backoff = ExponentialBackoff.new(min_interval, max_elapsed)
backoff.multiplier = 1.5
backoff.randomize_factor = 0.25

backoff.intervals_for(0..2) # [3.764, 6.587, 9.76]
```

You can peek what is the current interval:

```ruby
backoff.current_interval # 3.764
```

You can check if given iteration is one of intervals or maximum interval multiple:

```ruby
backoff = ExponentialBackoff.new(1, 10)
backoff.iteration_active?(4) # true
backoff.iteration_active?(20) # true
backoff.iteration_active?(3) # false
```

There is also sugar for executing block of code until successful with increasing intervals:

```ruby
backoff.until_success do |interval, retry_count|
  # do your thing
  # when last line in block evaluates to true, elapsed time clear and loop breaks
  # when false, increase interval and retry

  # you can break loop earlier if you want,
  # `nil` return value is considered a success
  return if retry_count > 3
end
```

Running tests
-------------

    ruby -Ilib -Itest test/exponential_backoff_test.rb


Supported rubies
----------------

Targets all Rubies (including Rubinius and JRuby) provided it's at least 1.9 mode.
