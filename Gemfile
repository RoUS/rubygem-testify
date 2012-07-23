source('http://rubygems.org')
#
# Pretty much all the goodies are in the gemspec
#
gemspec

RUBY_ENGINE = 'ruby' unless (defined?(RUBY_ENGINE))

group(:default) do
  gem('bundler', '>= 1.0.7')
  gem('json')
  gem('highline')
  gem('versionomy')
  gem('gettext')
  gem('git')
  gem('gli')
  gem('locale')
  gem('parseconfig')
  gem('versionomy')
end

group(:development, :test) do
  gem('aruba')
  gem('cucumber', '>= 0')
#  gem('extrapodate')
  gem('mocha')
  gem('rake')
  gem('rcov', '>= 0')
  gem('test-unit',
      :require	=> 'test/unit')
end
