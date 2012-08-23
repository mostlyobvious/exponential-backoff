ExponentialBackoff
==================

Too lazy to make retries to external services in a fashion that vendors recommend? Never heard of [exponential backoff](http://en.wikipedia.org/wiki/Exponential_backoff) technique? Now there is no excuse not to be nice.

Installation
------------

Add this line to your application's Gemfile:

    gem 'exponential-backoff'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install exponential-backoff

Usage
-----

```ruby
# Start with specifying minimal and maximal intervals,
# that is 4s and 60s respectively:
backoff_policy = ExponentialBackoff.new(4.0, 60.0)

# You can get intervals for specified range:
backoff_policy.intervals_for(0..5)
 => [4.0, 8.0, 16.0, 32.0, 60.0, 60.0]

# Enumerate on them:
backoff_policy.intervals.each { |interval| sleep(interval) }

# Or just get interval for requested, that is 3rd, iteration:
backoff.interval_at(3)
 => 32.0

# Intervals don't exceed maximal allowed time:
backoff.interval_at(20)
 => 60.0

# Backoff instance maintains state, you can ask for next interval...
backoff_policy.next_interval
 => 4.0
backoff_policy.next_interval
 => 8.0

# ...and reset it to start from beginning
backoff_policy.reset
backoff_policy.next_interval
 => 4.0

# Finally you can specify interval multiplier and randomization factor:
multiplier = 1.5
randomizer = 0.25
backoff_policy = ExponentialBackoff.new(4.0, 60.0, multiplier, randomizer)
backoff_policy.intervals_for(0..2)
 => [3.764, 6.587, 9.76]
```
