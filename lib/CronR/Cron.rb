# The files in this directory are part of CronR, a ruby library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the MIT License. A
# copy of the license should be enclosed with this project in the file
# LICENSE.txt.

require_relative 'utils'

module CronR

  # This is an array that is modified to represent a cron table along
  # with the necessary machinery to run it.
  #
  #   cron = Cron.new
  #   # Or
  #   cron = Cron.new(job1,job2,...)
  #
  # To start cron:
  # 
  #   cron.start
  #   
  # Jobs are instances of CronJob (although these are just glorified
  # hashes).
  # In fact, Cron expects job instances to respond to:
  # 
  #   runnable?(time) => if we can run now
  #   once? => this job is a one-off
  #   
  # @see CronJob 
  #   
  # Cron uses ruby's Time object to establish what the curren time is.
  # 
  #   cron.time => current time
  #   
  # You can however override cron's idea of the current time.
  # eg using ActiveSupport time zones:
  # 
  #   cron.time {
  #     Time.use_zone("Sydney") {
  #       Time.zone.now  
  #     }
  #   }
  #   
  #   cron.time => <the time in new timezone>
  # 
  # To alter cron after it's started (remember, it's just an array):
  # 
  #   cron.suspend {|arr|
  #     ... do something with cron ...
  #     ... arr == this cron instance ...
  #     arr << cron_job  # for example
  #   }
  #   
  # #suspend will wait for the thread dispatching jobs to be safely
  # sleeping.
  #
  # To gracefully stop cron:
  #
  #   cron.stop {
  #      ... do something now we've stopped ...
  #   }
  #
  #
  # RUNNABLE ITEMS
  # 
  # If a runnable item carries a proc, we don't run it - the thread
  # used in Cron is just for doing cron.
  # So runnable items are basically enqueued to @queue.
  # You can create an thread and have it dequeue this queue.
  # 
  #   Thread.new {
  #     loop {
  #       job = cron.queue.deq
  #       job.run  # Using CronJob#run .
  #       ...
  #     }
  #   }
  #   
  # You can also replace queue with something.  It should respond
  # to #enq and #deq and be thread-safe.  One example might be
  # to have #enq insert a record into a table.

  class Cron < Array

    attr_reader :thread,:mutex,:stopped,:suspended
    attr_accessor :debug,:queue
    attr_accessor :timezone

    # *items should consist of 0 or more items of form:
    #   [job_id(string),CronJob.new(...),thing]

    def initialize *jobs
      super()
      @stopped = true
      @suspended = false
      @queue = Queue.new
      jobs.each{|job|
        self.push(job)
      }
      @mutex = Mutex.new
      @timezone = nil
    end

    # Get current time.
    # 
    # If passed a block, the block will be used to get the time.

    def time
      if @timezone then
        Time.use_zone(@timezone) {
          Time.zone.now
        }
      else
        Time.now
      end
    end

    # Check each item in this array, if runnable push it on a queue.
    #
    # We assume that this item is or simlar to CronJob. We don't call
    # cron_job#job. That is the work for another thread esp. if #job
    # is a Proc.

    def run time=nil

      puts "[cron] run called #{Time.now}" if @debug
      time = self.time if time.nil?
      self.each{|cron_job|
        ok,details = cron_job.runnable?(time)
        if ok then
          @queue.enq(cron_job)
          if cron_job.once? then
            self.delete(cron_job)
          end
        end
      }

    end

    # Start cron.
    #
    # Will wake up every minute and perform #run.

    def start debug=false,method=:every_minute,*args
      @stopped = false
      @suspended = false
      @dead = Queue.new
      @thread = CronR::Utils.send(method,debug,*args) {
        time = self.time
        @mutex.synchronize {
          if @stopped then
            # It's important we put something on this queue ONLY AFTER
            # we've acquired the mutex...
            @dead.enq(true)
            true
          elsif @suspended then
          else
            self.run(time)
          end
        }
      }
    end

    # Suspend the thread.
    #
    # If block is given, it will only be called once the thread is
    # sleeping again.
    # You can use this to safely modify this array.

    def suspend &block
      if block_given? then
        @mutex.synchronize {
          begin
            @suspended = true
            block.call(self)
          ensure
            @suspended = false
          end
        }
      end
    end

    # Gracefully stop the thread.
    #
    # If block is given, it will be called once the thread has
    # stopped.

    def stop &block
      if block_given? then
        @stopped = true
        @suspended = false
        # Wait till something is put on the dead queue...
        # This stops us from acquiring the mutex until after @thread
        # has processed @stopped set to true.
        sig = @dead.deq
        # The cron thread should be dead now, or wrapping up (with the
        # acquired mutex)... 
        @mutex.synchronize {
          while @thread.alive?
            sleep 0.2
          end
          block.call(self)
        }
      end
    end

  end

end
