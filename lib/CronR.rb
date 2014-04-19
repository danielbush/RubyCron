# The files in this directory are part of CronR, a ruby library.
# Copyright (C) 2014 Daniel Bush
# This program is distributed under the terms of the MIT License. A
# copy of the license should be enclosed with this project in the file
# LICENSE.txt.

module CronR
  require 'active_support'
  #require 'active_support/time_with_zone'
  #require 'active_support/values/time_zone'
  require 'active_support/core_ext/time/zones'

  # Hack! - set Time::DATE_FORMATS if not there already.
  # 
  # If this is not set, activesupport may throw a hissy fit:
  #   uninitialized constant Time::DATE_FORMATS
  #   activesupport-4.0.4/lib/active_support/time_with_zone.rb:193:in `to_s'

  unless Time.const_defined?('DATE_FORMATS') then
    Time::DATE_FORMATS = {}
  end

  require_relative 'CronR/utils'
  require_relative 'CronR/Cron'
  require_relative 'CronR/CronJob'
end
