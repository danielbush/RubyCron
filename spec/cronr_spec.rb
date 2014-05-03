require_relative '../lib/CronR'
require 'pp'

Cron = CronR::Cron
Job  = CronR::CronJob

describe CronR::CronJob do
  describe "default behaviour" do
    it "should set parameters to true by default (= * in cron-speak)" do
      j = Job.new('job1')
      j[:minute].should == true
      j[:hour].should == true
      j[:day].should == true
      j[:month].should == true
      j[:dow].should == true
    end
    it "should be runnable every minute" do
      j = Job.new('job1')
      j.runnable?(Time.new(2014,1,1,1,1,0))[0].should == true
    end
  end
  describe "setting the minute" do
    it "should be runnable for a given minute in the hour" do
      j = Job.new('job1',min=1,hour=true)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=0))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=2))[0].should == false
    end
  end
  describe "setting the hour" do
    it "should be runnable for a given hour/minute" do
      j = Job.new('job1',min=1,hour=1)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=0))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1,hour=2,min=1))[0].should == false
    end
    it "should be runnable for a given hour every minute" do
      j = Job.new('job1',min=true,hour=1)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=0))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=2,min=1))[0].should == false
    end
    # This gets a bit combinatoric here, becuase we could test other
    # combinations where we set month, day of month, dow etc...
  end
  describe "setting the day of month" do
    it "should be runnable for a given minute/hour/day" do
      j = Job.new('job1',min=1,hour=1,day=1)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=2,hour=1,min=1))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1,hour=2,min=1))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=2))[0].should == false
    end
    it "should be runnable for a given day but every ..." do
      j = Job.new('job1',min=true,hour=1,day=1)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=2))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=3))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=2,min=3))[0].should == false
    end
  end
  describe "setting the month" do
    it "should be runnable for a given minute/hour/day/month" do
      j = Job.new('job1',min=1,hour=1,day=1,month=1)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=2,d=1,hour=1,min=1))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=2,hour=1,min=1))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1,hour=2,min=1))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=2))[0].should == false
    end
    it "should be runnable for a given month but every ..." do
      j = Job.new('job1',min=true,hour=1,day=1,month=1)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=2))[0].should == true
      j = Job.new('job1',min=1,hour=true,day=1,month=1)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=2,d=1,hour=1,min=1))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1,hour=2,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1,hour=2,min=2))[0].should == false
      # etc
    end
  end
  describe "setting the dow" do
    it "should be runnable for a given minute/hour/day/month/dow" do
      # 0 = sunday, 1 = monday etc...
      # Just a note:
      t = Time.new(2014,m=1,d=1,hour=1).wday.should == 3
      t = Time.new(2014,m=1,d=1,hour=1).wednesday?.should == true
      # so...
      j = Job.new('job1',min=1,hour=1,day=1,month=1,dow=3)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=2,hour=1,min=1))[0].should == false
    end
    it "should distinguish day month from day of week" do
      j = Job.new('job1',min=1,hour=1,day=true,month=1,dow=3)
      j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == true
      j.runnable?(Time.new(2014,m=1,d=1+1,hour=1,min=1))[0].should == false
      j.runnable?(Time.new(2014,m=1,d=1+7,hour=1,min=1))[0].should == true
    end
    # etc
  end
  describe "non-numeric/non-true arguments" do
    describe "minute" do
      it "should handle ranges" do
        j = Job.new('job1',min=(0..58).step(2))
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=0))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == false
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=2))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=58))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=59))[0].should == false
      end
      it "should handle arrays" do
        j = Job.new('job1',min=(0..58).step(2).to_a)
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=0))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == false
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=2))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=58))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=59))[0].should == false
      end
    end
    # Picking something more exotic...
    describe "dow" do
      it "should handle arrays" do
        j = Job.new('job1',true,true,true,true,dow=[0,1,6])
        j.runnable?(Time.new(2014,m=1,d=1,hour=1,min=1))[0].should == false
        j.runnable?(Time.new(2014,m=1,d=2,hour=1,min=1))[0].should == false
        j.runnable?(Time.new(2014,m=1,d=3,hour=1,min=1))[0].should == false
        j.runnable?(Time.new(2014,m=1,d=4,hour=1,min=1))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=5,hour=1,min=1))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=6,hour=1,min=1))[0].should == true
        j.runnable?(Time.new(2014,m=1,d=7,hour=1,min=1))[0].should == false
      end
    end
  end

  describe "getting/setting jobs" do
    it "can set job using #initialize" do
      proc = lambda{:job1}
      j = Job.new('job1',&proc)
      j[:job].should == proc
    end
    it "can set job using #job=" do
      proc = lambda{:job1}
      j = Job.new('job1')
      j.job = proc
      j[:job].should == proc
    end
    it "can set job using #job {...}" do
      proc = lambda{:job1}
      j = Job.new('job1')
      j.job &proc
      j[:job].should == proc
    end
  end

  describe "running jobs" do
    it "will call procs " do
      proc = lambda{:job1}
      j = Job.new('job1',&proc)
      j.run.should == :job1
    end
    it "will return non-procs" do
      j = Job.new('job1')
      j.job = [1,2,3]
      j.run.should == [1,2,3]
    end
  end

  describe "setting time parameters" do
    it "can set the cron elements" do
      j = Job.new('job1')
      [j[:minute],j[:hour],j[:day],j[:month],j[:dow]].should == [true,true,true,true,true]
      j.set(1,2,3,4,5)
      [j[:minute],j[:hour],j[:day],j[:month],j[:dow]].should == [1,2,3,4,5]
    end
  end

  describe "once?" do
    it "should only return true if :once is truthy" do
      j = Job.new('job1')
      j.once?.should == false
      j[:once] = true
      j.once?.should == true
      j[:once] = false
      j.once?.should == false
      j[:once] = nil
      j.once?.should == false
      j.delete(:once)
      j.once?.should == false
    end
  end
end

describe CronR::Cron do

  describe "time handling" do

    it "should fetch time" do
      c = Cron.new
      c.time.class.should == Time
    end

    it "should allow us to set a timezone" do
      @cron = Cron.new

      @cron.timezone = "Australia/Sydney"
      @cron.timezone.should == "Australia/Sydney"
      @cron.time.utc_offset.between?(10*3600,11*3600).should == true

      @cron.timezone = "Australia/Perth"
      @cron.timezone.should == "Australia/Perth"
      @cron.time.utc_offset.between?(7*3600,8*3600).should == true
    end

  end

  describe "adding jobs" do
    it "should allow us to do this via #initialize" do
      c = Cron.new(j1=Job.new(1),j2=Job.new(2),j3=Job.new(3))
      c.size.should == 3
      c.first.should == j1
    end
    it "should allow us to do this via #suspend" do
      c = Cron.new
      c.suspend {|arr|
        arr << Job.new(1)
        arr << Job.new(2)
        arr << Job.new(3)
      }
      c.size.should == 3
      c.first[:id].should == 1
    end
  end

  describe "execution" do
    it "should run runnable jobs" do
      j1 = Job.new(1,min=1)
      j2 = Job.new(1,min=2)
      c = Cron.new(j1,j2)
      t=Time.new(2014,1,1,1,min=1)

      c.queue.size.should == 0
      j1.runnable?(t)[0].should == true
      j2.runnable?(t)[0].should == false
      c.run(t)
      c.queue.size.should == 1
      c.queue.deq(true) == j1
      c.size.should == 2
    end

    it "should remove jobs that have :once key set to true" do
      t=Time.new(2014,1,1,1,min=1)
      j = Job.new(1)
      j[:once] = true
      c = Cron.new(j)

      c.queue.size.should == 0
      j.runnable?(t)[0].should == true
      c.run(t)
      c.size.should == 0
    end
  end

  # This is the hardest one to test.  #start will start a thread that
  # should wake every minute. How can we test this automatically?
  # To test it actually working, see examples/.

  describe "control / lifecycle" do

    before(:each) {
      @results = []
      # This job should run every minute...
      @job = Job.new(1) {@results.push(:job1)}
      @cron = Cron.new(@job)
      # Need to process the job...
      @thread = Thread.new {
        loop {
          @job = @cron.queue.deq
          @job.run
        }
      }
    }

    after(:each) {
      @thread.kill
    }

    it "should start" do
      @cron.stopped.should == true
      @cron.suspended.should == false
      # Make cron run sub-minute (every second)
      @cron.start(false,:every,1)
      @cron.stopped.should == false
      @cron.suspended.should == false
      puts "sleeping 1.2"; sleep 1.2
      @results.size.should == 1
    end

    it "should suspend" do
      @cron.start(false,:every,1)
      @cron.suspend {
        size = @results.size
        @cron.stopped.should == false
        @cron.suspended.should == true
        puts "sleeping 1.2"; sleep 1.2
        @results.size.should == size
      }
    end

    it "should stop" do
      @cron.start(false,:every,1)
      @cron.stop {
        @cron.suspended.should == false
        @cron.stopped.should == true
        @cron.thread.alive?.should == false
      }
    end

  end


end
