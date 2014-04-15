# RubyCron

Consists of:

* ```Cron```
  * a glorified Array representing sequence of CronJob instances
  * a thread that wakes up every minute to determine if jobs are runnable
  * if so, they get put on to a queue
  * you have to deq the queue and do something with the job
* ```CronJob```
  * represents the standard cron parameters and some sort of payload or job to run

# Status

Pretty early days.  

This was part of an experiment in subclassing basic datastructures and playing a bit more with threads.

Bit naughty, no specs at the moment.

See Cron.rb and CronJob.rb in lib/* for current documentation.

Dabbled briefly with sub-minute timings - see utils.rb in lib/* but
stopped after my eyes started to water. That being said there are some
singleton util methods that might be of use in this regard.

