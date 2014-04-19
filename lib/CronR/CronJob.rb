# The files in this directory are part of CronR, a ruby library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the MIT License. A
# copy of the license should be enclosed with this project in the file
# LICENSE.txt.

module CronR

  # An instance (cp) of this class (a subclass of hash) represents the
  # standard cron parameters along with an id and something
  # representing the job (eg a lambda).
  #
  # cp = CronJob.new('id1')
  #   => '* * * * *' cron job id1 with no job
  # cp = CronJob.new('id2') {... a proc...}
  #   => '* * * * *' cron job id1 with a proc
  #   => #job => will 'call' the proc
  # cp = CronJob.new('id2')
  # cp.job = {...} => a non-proc job
  # 
  # CRON PARAMETERS:
  # 
  # cp[s] where s can be :minute,:hour,:day,:dow,:month .
  # 
  # cp[s] = true
  #   ie '*' in a crontab
  # cp[s] = i  (i.kind_of?(Fixnum))
  #   => for minutes we have 0-5, hours 0-23, etc
  # cp[s] = [i,...] (array)
  #   => cp[:minute] =
  # cp[s] = (0..58).step(2)
  #   => equivalent to */2 in cron
  #
  # For each component: [:minute,:hour,:day,:dow,:month] we can
  # then interpret the settings as:
  # [true,true,true,true,true]
  #   => run every minute of every hour of every month of every day of
  #      the week
  # [5,true,true,true,true]
  #   => run 5 minutes past the hour
  # [(0..55).step(5),true,true,true,true]
  #   => run every 5 minutes
  # [[10,30,50],true,true,true,true]
  #   => run on 10th, 30th and 50th minute of the hour

  class CronJob < Hash

    def initialize id,minute=true,hour=true,day=true,month=true,dow=true,&block
      super() {nil}
      self.set(minute,hour,day,month,dow)
      self[:id] = id
      if block_given? then
        self.job &block
      end
    end

    def set minute=true,hour=true,day=true,month=true,dow=true
      self[:minute] = minute
      self[:hour] = hour
      self[:day] = day
      self[:month] = month
      self[:dow] = dow # 0=sunday,...,6=Saturday
    end

    # Get job or set job via block.
    #
    # cj.job
    # cj.job {|cj|...}

    def job &block
      if block_given? then
        #self[:job] = block.call(self)
        self[:job] = block
      else
        self[:job]
      end
    end

    def job= thing
      self[:job] = thing
    end

    # Run the job.
    #
    # This is a convenience method to handle calling proc based
    # :job's.

    def run
      case self[:job]
      when Proc
        self[:job].call
      else
        self[:job]
      end
    end

    # Return true if job is runnable at the given time.
    #
    # Note we expect an instance of Time.
    # ActiveSupport can be used to give us time zones in Time.
    #
    # Example
    #   ok,details = runnable?(Time.now)

    def runnable? time
      result = [:minute,:hour,:day,:dow,:month].map{|ct|
        if self[ct] == true then
          true
        else
          case ct
          when :month,:day,:hour
            val = time.send(ct)
          when :dow
            val = time.wday
          when :minute
            val = time.min
          end

          case self[ct]
          when Numeric # Should be Fixnum
            self[ct] == val
          else # Assume array-like thing...
            self[ct].include?(val)
          end
        end
      }
      # Everything should be true to make us eligible for running:
      [result.inject(true){|s,v| s && v},result]
    end

    # Return true if the job is intended to only be run as a one-off.

    def once?
      self[:once] || false
    end

  end

end
