require('versionomy')

module Testify

  #
  # Initial version (in Perl) which didn't get very far.
  #
  $version = Versionomy.parse('0.1.0')
  #
  # Initial port from Perl to Ruby
  #
  $version = $version.change(:minor => '2')

  VERSION = $version.to_s.freeze

end
