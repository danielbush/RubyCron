require_relative '../lib/CronR'
require 'pp'

Cron = CronR::Cron
Job  = CronR::CronJob

cron = Cron.new
cron.debug = true

# Optional
# Set timezone...
cron.timezone = "Australia/Sydney"
p cron.time

cron.start

# So cron is now running, but it's not actually doing much because it
# doesn't have any jobs.

# Let's change that...

cron.suspend {|arr|
  # If you only specific 1 arg, the cron job is '* * * * *', so
  # it runs every minute...
  arr << Job.new('job1') {
    puts "[job1] You should see this every minute... #{cron.time}"
  }
  # Note: arr == cron

  # Here's a job that will run every 2nd minute...
  arr << Job.new('job2',(0..58).step(2)) {
    puts "[job2] You should see this every */2 minutes... #{cron.time}"
  }
}

# Suspend will actually wait for the thread in cron to finish cycling
# over the entries in cron (at the beginning of every minute).
# We can then add a job.
# Kind of assuming here that you won't be doing anything super-long in
# the suspend-block... be aware that it could hold up the next cycle
# in cron as well.

# Now we need to do something with jobs that cron deems runnable...
# The thread in cron won't run them, that's not its job...

Thread.new {
  loop {
    job = cron.queue.deq
    job.run
  }
}

# Note that cron is just an array...
puts "Here is cron (it's just an array of the jobs we added)..."
puts '-'*60
pp cron
puts '-'*60

cron.thread.join  
