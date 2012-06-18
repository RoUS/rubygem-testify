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
end

group(:development, :test) do
  gem('aruba')
  gem('cucumber')
  gem('mocha')
  gem('rake')
  gem('rcov')
  gem('test-unit',
      :require	=> 'test/unit')
end

group(:doc) do
  gem('rdoc')
  gem('yard')
end
