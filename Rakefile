# encoding: utf-8

require('rubygems')
require('bundler')
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts(e.message)
  $stderr.puts("Run 'bundle install' to install missing gems")
  exit(e.status_code)
end
require('rake')

require('jeweler')
require('lib/version')
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see
  # http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = 'testify'
  gem.homepage = 'http://github.com/RoUS/testify'
  gem.license = 'Apache 2.0'
  gem.summary = %Q{Manage test output regressions}
  gem.description = %Q{TODO: longer description of your gem}
  gem.email = 'The.Rodent.of.Unusual.Size@GMail.Com'
  gem.authors = ['Rodent of Unusual Size']
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require('rake/testtask')
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require('rcov/rcovtask')
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

require('cucumber/rake/task')
Cucumber::Rake::Task.new(:features)

task(:default => :test)

require('rdoc/task')
Rake::RDocTask.new do |rdoc|
  version = Testify::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "testify #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
