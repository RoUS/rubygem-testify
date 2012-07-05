source('http://rubygems.org')
#
# Pretty much all the goodies are in the gemspec
#
gemspec

RUBY_ENGINE = 'ruby' unless (defined?(RUBY_ENGINE))

group(:default) do
  gem('bundler', '>= 1.0.7')
  gem('json')
  gem('versionomy')
  gem('git')
  gem('gli')
  gem('parseconfig')
  gem('versionomy')
end

group(:development) do
end

group(:test) do
end

group(:doc) do
  gem('rdoc')
  gem('yard')
end

group(:development, :test) do
  gem('aruba')
  gem('bundler', '>= 1.0.0')
  gem('cucumber', '>= 0')
#  gem('extrapodate')
  gem('jeweler', '~> 1.6.4')
  gem('mocha')
  gem('rake')
  gem('rcov', '>= 0')
  gem('rdoc', '>= 2.4.2')
  gem('test-unit',
      :require	=> 'test/unit')
end
