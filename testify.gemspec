# -*- encoding: utf-8 -*-
$:.push(File.expand_path('../lib', __FILE__))

require('testify/version')

Gem::Specification.new do |s|
  s.name		= 'testify'
  s.version		= Testify::VERSION
  s.platform		= Gem::Platform::RUBY

  s.authors		= [ 'Ken Coar' ]
  s.summary		= %q{Interface to the Testify graphing tool}
  s.email		= %q{coar@apache.org}
  s.homepage		= %q{http://github.com/glejeune/Testify}
  s.description 	= %q{Ruby/Testify provides an interface to layout and generate images of directed graphs in a variety of formats (PostScript, PNG, etc.) using Testify.}

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
Since version 0.9.2, Ruby/Testify can use Open3.popen3 (or not)
On Windows, you can install 'win32-open3'

You need to install Testify (http://testify.org/) to use this Gem.

For more information about Testify :
* Doc : http://rdoc.info/projects/glejeune/Testify
* Sources : http://github.com/glejeune/Testify
* NEW - Mailing List : http://groups.google.com/group/testify

Last (important) changes :
* Testify#add_edge is deprecated, use Testify#add_edges
* Testify#add_node is deprecated, use Testify#add_nodes
* Testify::Edge#each_attribut is deprecated, use Testify::Edge#each_attribute
* Testify::GraphML#attributs is deprecated, use Testify::GraphML#attributes
* Testify::Node#each_attribut is deprecated, use Testify::Node#each_attribute
  EOT

  s.add_development_dependency('rake')
  s.add_development_dependency('rdoc')
end
