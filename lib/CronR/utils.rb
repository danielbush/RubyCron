# The files in this directory are part of CronR, a ruby ibrary.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the MIT License. A
# copy of the license should be enclosed with this project in the file
# LICENSE.txt.

module CronR

  module Utils

    # Parse a single cron parameter into a format that CronR uses.
    #
    # Currently not used directly by CronR.  But may be handy for
    # translating cron parameters.
    #
    # '*' => true
    # '1' => 1
    # '1-3' => [1,2,3]
    # Other forms which translate to arrays:
    # '*/3' '1-5/2' '2,4,8' '2-4,6-8'
    #
    # In the case of */3 we do: (1..59).step(3).to_a
    # which will hopefully cover all cases.

    def self.parse_param str
      parts = str.split(',')
      if parts.empty? || parts.detect{|i| i.empty? } then
        raise "Not enough information to process parameter: '#{str}'."
      end
      parts.map { |p|
        n, step = p.split('/')
        raise "No number before slash: '#{str}'" if n.empty?
        a, b = n.split('-')
        raise "No number before hyphen: '#{str}'" if a.empty?
        a = a.strip
        raise "Not a number or asterisk: '#{a}'" unless /^\d+$|^\*$/ === a
        if b then
          a, b = a.to_i, b.to_i
          if step then
            (a..b).step(step.to_i).to_a
          else
            (a..b).to_a
          end
        else
          case a
          when '*'
            if step then
              # Bit cheap, basically we'll cover ourselves for all
              # component types by going up to 59
              (0..59).step(step.to_i).to_a
            else
              return true  # ick, exit def
            end
          else
            [a.to_i]
          end
        end
      }.flatten
    end

    # Wake up every minute and call &block.
    #
    # Returns the thread that does the waking up.
    # If &block returns true, then stop.

    def self.every_minute debug=false,&block
      mil = 1000000
      secs = 60.0
      Thread.new {
        now = Time.now
        wait = secs-now.sec-now.usec.to_f/mil
        #p "[every_minute] sleeping #{wait}" if debug
        sleep wait
        loop {
          result = block.call
          if result==true then
            break
          end
          now = Time.now
          wait = secs-now.sec-now.usec.to_f/mil
          #p "[every_minute] sleeping #{wait}" if debug
          sleep(wait)
        }
      }
    end

    # Wake up every 'secs' number of seconds and call block.
    #
    # We measure 'secs' after the function call.  So it is not aligned
    # to anything.

    def self.every secs,debug=false,&block
      Thread.new {
        loop {
          result = block.call
          if result==true then
            break
          end
          #p "[every] sleeping #{secs}" if debug
          sleep secs
        }
      }
    end

    # Make a function that returns time to wait till the next secs-th
    # second of each minute.
    #
    # MOTIVATION
    # 
    # every_minute wakes up every minute on the minute.
    # Can we wake up every several seconds, on the second?
    # Can we break a minute up into intervals starting from the 0th
    # second in the minute?
    # 
    #   l = make_waitsecs_time(3)
    #   wait = l.call
    #   sleep(wait)
    #   # So, right *now*:
    #   # Time.now.sec ~ s where (0..57).step(3).to_a.include?(s)
    #

    def self.make_waitsecs_time secs
      if secs < 1 || secs > 60 then
        raise "secs must be 1-60"
      end
      mil = 1000000
      lambda{|time=nil|
        time = Time.now if time.nil?
        sec = time.sec
        usec = time.usec
        frac = usec.to_f/mil
        remainder = secs - ((sec+1) % secs)
        remainder -= frac
        if remainder < 0
          # TODO if frac is almost zero, return zero here?
          remainder + secs
        else
          remainder
        end
      }
    end

    # Make a function that returns time to wait till the next secs-th
    # second of the unix epoch.
    # 
    # MOTIVATION
    # 
    # make_waitsecs_time breaks up the minute starting from the 0th second
    # and the maximum cycle is therefore 60.
    # Here we can apply '% secs' for arbitrary value 'secs' up to the current
    # epoch, although such large values would be of little use.

    def self.make_waitsecs_epoch secs
      if secs < 1 then
        raise "secs must be > 1"
      end
      mil = 1000000
      lambda{|time=nil|
        time = Time.now if time.nil?
        sec = time.to_i # unix timestamp
        usec = time.tv_usec # fraction unix component
        frac = usec.to_f/mil
        remainder = secs - ((sec+1) % secs)
        remainder -= frac
        if remainder < 0
          # TODO if frac is almost zero, return zero here?
          remainder + secs
        else
          remainder
        end
      }
    end

  end

end
