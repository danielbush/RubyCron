Gem::Specification.new do |s|
  s.name        = 'CronR'
  s.version     = '0.1.4'
  s.date        = '2014-05-03'
  s.summary     = "An implementation of cron in ruby."
  s.description = "Simple, thread-based, light-weight cron implementation."
  s.authors     = ["Daniel Bush"]
  s.email       = 'dlb.id.au@gmail.com'
  s.files       = [
    "lib/CronR.rb",
    "lib/CronR/utils.rb",
    "lib/CronR/CronJob.rb",
    "lib/CronR/Cron.rb",
  ]
  s.homepage    = 'http://github.com/danielbush/RubyCron'
  s.license       = 'MIT'
  s.add_runtime_dependency 'activesupport','>=3.0.0'
  s.add_development_dependency 'rspec'
end
