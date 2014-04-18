# CronR

Pronounced "cron-rrrr" ...

...because RubyCron was taken.  So was cronic for that matter... and RCron.

CronR is a light-weight implementation of a cron-like system.

For the impatient, head over to examples/ .

For the patient, there's documentation of the Cron and CronJob classes in the code in lib/.

Consists of:

* ```Cron```
  * a glorified Array representing sequence of CronJob instances
  * a thread that wakes up every minute to determine if jobs are runnable
  * if so, they get put on to a queue
  * you have to deq the queue and do something with the job
* ```CronJob```
  * represents the standard cron parameters and some sort of payload or job to run

See Cron.rb and CronJob.rb in lib/* for current documentation.

## Status

Pretty early days.  

This was part of an experiment in subclassing basic datastructures and playing a bit more with threads.

Bit naughty, no specs at the moment.

Dabbled briefly with sub-minute timings - see utils.rb in lib/* but
stopped after my eyes started to water. That being said there are some
singleton util methods that might be of use in this regard.

## Setting timezones

An instance of ```Cron``` can use a specific timezone.

Something like this

```ruby
require 'rubygems'
require 'active_support'
#require 'active_support/time_with_zone'
#require 'active_support/values/time_zone'
require 'active_support/core_ext/time/zones'

cron = Cron.new
cron.time {
  Time.use_zone("Australia/Sydney") {
    Time.zone.now
  }
}

cron.time => <time with timezone>
```

## Contact

Pretty bad with email.  Try danb with catalyst-au.net as the domain.
