# -*- encoding: utf-8 -*-
$:.push(File.expand_path('../lib', __FILE__))

require('lib/version')

Gem::Specification.new do |s|
  s.name		= 'testify'
  s.version		= Testify::VERSION
  s.platform		= Gem::Platform::RUBY

  s.authors		= [ 'Ken Coar' ]
  s.summary		= %q{Interface to the Testify graphing tool}
  s.email		= %q{coar@apache.org}
  s.homepage		= %q{http://github.com/RoUS/testify}
  s.description 	= %q{}

  s.files       	= `git ls-files`.split("\n")
  s.test_files  	= `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables 	= `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths	= [
                           'lib',
                          ]

  s.rubyforge_project	= 'testify'
  s.extra_rdoc_files	= [
                           'README.rdoc',
                           'COPYING.rdoc',
                           'AUTHORS.rdoc',
                           'CHANGELOG.rdoc',
                          ]
  s.rdoc_options	= [
                           '--title',
                           'Ruby/Testify',
                           '--main',
                           'README.rdoc',
                          ]
  s.post_install_message = <<-EOT
  EOT

  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc', '>= 2.4.2')
end
