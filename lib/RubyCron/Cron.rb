# The files in this directory are part of BeerBot, a a ruby irc bot library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the MIT License. A
# copy of the license should be enclosed with this project in the file
# LICENSE.txt.

require_relative 'utils'

module RubyCron

  # This is an array that is modified to represent a cron table along
  # with the necessary machinery to run it.
  #
  #   cron = Cron.new(job1,job2,...)
  #   cron.start
  #   
  # Jobs are instances of CronJob (although these are just glorified
  # hashes).
  # In fact, Cron expects job instances to respond to:
  # 
  #  runnable?(time) => if we can run now
  #  once? => this job is a one-off
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
  # So runnable items are basically enqueued to @schedule.
  # @schedule is just a queue.
  # You can create an thread and have it dequeue this queue.
  # You can also replace queue with something.  It should respond
  # to #enq and #deq and be thread-safe.  One example might be
  # to have #enq insert a record into a table.

  class Cron < Array

    attr_reader :thread,:mutex
    attr_accessor :debug,:queue

    # *items should consist of 0 or more items of form:
    #   [job_id(string),CronJob.new(...),thing]

    def initialize *jobs
      super()
      @queue = Queue.new
      jobs.each{|job|
        self.push(job)
      }
      @mutex = Mutex.new
    end

    # Get current time.
    # 
    # If passed a block, the block will be used to get the time.

    def time &block
      if block_given? then
        @time = block
      else
        @time ||= lambda{Time.now}
        @time.call
      end
    end

    # Check each item in this array, if runnable push it on a queue.
    #
    # We assume that this item is or simlar to CronJob. We don't call
    # cron_job#job. That is the work for another thread esp. if #job
    # is a Proc.

    def run

      p "[cron] run called #{Time.now}" if @debug
      self.each{|cron_job|
        ok,details = cron_job.runnable?(self.time)
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

    def start debug=false
      @stop = false
      @suspend = false
      @thread = RubyCron::Utils.every_minute(debug) {
        @mutex.synchronize {
          if @stop then
            true
          elsif @suspend then
          else
            self.run
          end
        }
      }
    end

    # Allows you to use sub-minute intervals - useful for live
    # testing.
    #
    # DON'T RUN THIS NORMALLY, eligible entries will run multiple
    # times a minute.

    def start_test secs
      @stop = false
      @suspend = false
      @thread = RubyCron::Utils.every(secs,true) {
        @mutex.synchronize {
          if @stop then
            true
          elsif @suspend then
          else
            self.run
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
      @suspend = true
      if block_given? then
        @mutex.synchronize {
          begin
            block.call(self)
          ensure
            @suspend = false
          end
        }
      end
    end

    # Gracefully stop the thread.
    #
    # If block is given, it will be called once the thread has
    # stopped.

    def stop &block
      @stop = true
      if block_given? then
        @mutex.synchronize {
          block.call(self)
        }
      end
    end

    # For 'p'.

    def inspect
      self.map {|job|
        job.inspect
      }.join("\n")
    end

  end

end
