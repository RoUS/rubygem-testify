source('https://rubygems.org')
#
# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
#

group(:default) do
  gem('git')
  gem('gli')
  gem('parseconfig')
  gem('versionomy')
end

group(:development) do
  gem('bundler', '>= 1.0.0')
#  gem('extrapodate')
  gem('jeweler', '~> 1.6.4')
  gem('rcov', '>= 0')
end

group(:test) do
  gem('aruba')
end

group(:test, :development) do
  gem('cucumber', '>= 0')
  gem('rdoc', '>= 2.4.2')
  gem('test-unit', '~>2.3')
end
