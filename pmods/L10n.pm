package L10n;
#
# $Id: L10n.pm,v 1.1 2007/07/30 02:17:10 coar Exp $
#
#   Module L10n, part of the Testify project
#   Copyright 2006 The Testify Project
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this package or any files in it except in
#   compliance with the License.  A copy of the License should be
#   included as part of the package; the normative version may be
#   obtained a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Package for accessing a localisation library.
#

use strict;
use vars qw( $AUTOLOAD $VERSION @verbs );

use Carp;
use Data::Dumper;
use Fcntl;
use File::Path;
use File::Spec::Functions;
use SDBM_File;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = sprintf('%d.%03d', q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
    @ISA         = qw (Exporter);
    #
    # Give a hoot, don't pollute; do not export more than needed by default
    #
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
    #
    # Now some setup.
    #
}

=pod

=head1 NAME

L10n - Access localised text

=head1 SYNOPSIS

 use L10n;
 $ldb = new L10n(lang => 'en', libdir => '/usr/local/lib/L10n');
 $text = $ldb->lookup('base string');
 $laststatus = $ldb->status(); # zero means success
 $ldb->config(lang => 'pt_BR');
 @localised_keys = $ldb->keys();

=head1 DESCRIPTION

This module is part of the Testify project (L<http://testify.sourceforge.net>).
It accesses localised text (such as help or documentation) according to
locale settings.  It's kind of a simpler poor-man's version of GNU's
B<gettext> library.

=head1 USAGE

This module is intended to be used solely in an object-oriented manner.
All of its methods are described below.

=cut

#
# Here come the methods, each preceded by its POD..
#
=pod

=head2 new

 $ldb = new L10n(%config);
 $ldb = L10n->new(%config);

This is the constructor for the L10n class of object.  It takes as arguments
a list of key/value pairs, or a hash reference, which is used to set
up the operating parameters of the object.

See the B<config> method for details about the different configuration
options.

=cut

#
# new L10n(
#          lang   => language,
#          libdir => path,
#         )
#
sub new {
    my ($class, @parameters) = @_;
    my $self = bless({}, ref($class) || $class);
    $self->config(
                  lang          => $ENV{'LC_ALL'} || $ENV{'LANG'} || 'en',
                  lang_fallback => 'en',
                  libdir        => 'l10n',
                  newlines      => 0,
                  onabsent      => '[Unable to locate localisation '
                                   . "of '%s' for locale '%s']",
                 );
    $self->config(@parameters);
    $self->status(0);
    $self->load() if (! $self->{config}->{noload});
    return $self;
}

=pod

=head2 config

 $ldb->config(%config);

Set up an L10n object for use, or changes parameters after creation.
B<create> is explicitly invoked by the B<new> method, but some
can be changed after the object has been loaded.

Possible configuration options;

=over 2

=over 4

=item lang

Specifies the locale language to use.  If omitted, the B<LC_ALL> and
B<LANG> environment variables are used to determine the default.  If
no user setting can be determined, the object will be configured to use
the 'en' language.

=item lang_fallback

Specifies a language to use as a backup if the database for the primary
language cannot be found or opened.

=item libdir

Indicates the full filesystem path to the directory where the localisation
databases (*.ldb files) are located.

=item newlines

Controls how the last line ending of localised text fetch with
B<lookup> should be handled:

=over 4

=item B<-1>

Strip terminal newlines.  All \r and \n characters at the end of the
localised text will be removed before the result is passed back to the
caller.

=item B<0>

Don't make any changes; return the localised text, newlines (or not) and
all.

=item B<1>

Add a terminal newline (\n character) to localised text if it doesn't
already have a trailing \r or \n.

=back

B<newlines =E<gt> 0> is the default.

=item noload

When specified with a non-zero value during constructor invocation, this
causes the object lo defer actually loading the localisation library.
This is useful if you want to set various configuration options
sequentially before actually getting it ready to use.

The default is to attempt to load the appropriate library on
object creation.

=item onabsent

Specifies a string to use to indicate no localised text could be
found when an appropriate message can't be found in the open
library.

=back

=back

=cut

sub config {
    my $self = shift;
    my %cfg = @_;
    for (keys(%cfg)) {
        my $ckey = $_;
        $ckey =~ s§^[^-\w]+§§;
        $ckey = lc($ckey);
        if (($ckey =~ m§^(?:lang(?:_fallback)?|libdir|noload)$§)
            && $self->{loaded}) {
            carp("Cannot change '$ckey' setting on a loaded object");
            next;
        }
        $self->{config}->{$ckey} = $cfg{$_};
    }
    $self->status(0);
    return;
}

=pod

=head2 keys

 @localised = $ldb->keys();

Returns a list of all the keys for which localised text has
been defined in the current library.

=cut

sub keys {
    my $self = shift;
    return sort(keys(%{$self->{l10n}}));
}

=pod

=head2 load

 $ldb->load();

Loads the localisation definitions as set up by the B<new> and B<config>
methods.  Once the library has been loaded, the language and fallback
language cannot be changed, and the library cannot be reloaded.

=cut

sub load {
    my $self = shift;
    #
    # Read in the localisation info.
    #
    my $newlang = $_[0] || $self->{config}->{lang};
    my $fblang = $_[1] || $self->{config}->{lang_fallback};
    my $l10ndb = catfile($self->{config}->{libdir}, "$newlang.ldb");
    my %ldb;
    if (! -r "$l10ndb.pag") {
        carp("Localisation database $l10ndb not found; "
             . "no local support for language '$newlang'");
        if ($fblang) {
            carp("Attempting to fall back to '$fblang'");
            $self->load($fblang);
        }
        $self->status(1);
        return;
    }
    tie(%ldb, 'SDBM_File', $l10ndb, O_RDONLY, 0666)
        or do {
            carp("Can't open localisation database '$l10ndb': $!");
            return;
        };
    for (CORE::keys(%ldb)) {
        $self->{l10n}->{$_} = $ldb{$_};
    }
    untie(%ldb);
    $self->status(0);
    $self->{loaded} = 1;
    return;
}

=pod

=head2 lookup

 $text = $ldb->lookup($key);
 $text = $ldb->lookup($key, $altkey);
 $text = $ldb->lookup($key, [$altkey], $arg, $arg, ...);

This is the workhorse of the module.  The B<lookup> method accesses
the library and returns the localised text associated with the
specified key.  If the key isn't found, the C<$altkey> key will
be used.  If no localised text for the alternate key can be found,
or the altkey argument is undefined, the object's B<onabsent>
configuration setting will be used (see the B<config> method).


The final text may be used as a B<sprintf> format string, and
the additional method arguments will be used with it.

If the primary key isn't found, the arguments are ignored and
the primary key and the object's language are used instead.
This allows the altkey to complain about the missing primary
key.

Trailing newlines in the localised text are treated according to
the B<newlines> configuration option (I<q.v.>) before the
text is returned to the caller.

=cut

#
# $text = $l10n->lookup(key, [default-key], arg...)
#
sub lookup {
    my $self = shift;
    my $key = shift;
    my $default = shift || '_unlocalised';
    my $text;

    if (! $self->{loaded}) {
        carp("Must be configured before lookups");
        return undef;
    }
    if (! defined($text = $self->{l10n}->{$key})) {
        if (! defined($text = $self->{l10n}->{$default})) {
            $text = $self->{config}->{onabsent};
        }
        @_ = ($key, $self->{config}->{lang});
    }
    if (@_ && ($text =~ /%/)) {
        $text = sprintf($text, @_);
    }
    if (my $nl = $self->{config}->{newlines}) {
        if ($nl < 0) {
            print "Chomping: " . length($text);
            $text =~ s§[\r\n]+$§§;
            print ':' . length($text) . "\n";
        }
        else {
            $text .= "\n" if ($text !~ m§[\r\n]$§);
        }
    }
    return $text;
}

=pod

=head2 status

 $laststatus = $ldb->status();

This method allows you to programmatically determine whether the
last operation performed with the object was successful or not.
A value of 0 means unqualified success; 1 means either total
failure or partially recovered failure.  For example, if a
B<lookup> call failed to find the primary key, but was able
to use the alternate, the status value will be 1.

=cut

sub status {
    my $self = shift;
    my $was = $self->{status};
    if (@_) {
        $self->{status} = $_[0];
    }
    return $was;
}


1;

__END__

=pod

=head1 BUGS

None known.

=head1 SUPPORT

Support of this module is provided by the Testify project at
SourceForge (L<http://testify.sourceforge.net/>).  Use the
issue tracker and mailing lists to report problems and
ask for help.

=head1 AUTHOR

 Ken Coar
 CPAN ID: ROUS
 Ken@Coar.Org
 http://Ken.Coar.Org/

 Copyright licensed to the Testify project.

=end text

=head1 COPYRIGHT

This program is free software licensed under the...

    Apache Software License (Version 2.0)

The full text of the license can be found in the
LICENCE file included with this module.

=head1 SEE ALSO

=over 2

=item The Testify project, L<http://testify.sourceforge.net/>

=item GNU B<gettext>, L<gettext(1)> and C<info gettext>

=back

=cut

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# c-basic-offset: 4
# End:
#
