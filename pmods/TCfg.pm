package TCfg;

use strict;
use vars qw($VERSION);

use Symbol;
use Carp;
use Filter;
use Data::Dumper;
use File::Path;
use File::Spec::Functions;

use lib 'pmods/';
use TCfg::Block;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    use vars qw ($sectionmap %valid_options);
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
    $sectionmap = {
                   '[filter]' => 'Filter'
                  };
    %valid_options = ();
}

#
# Just for cleaning up..
#
sub DESTROY {
    my $self = shift;
}

sub config {
    my $self = shift;
    #
    # Handle the case of simply asking for a current setting
    #
    if (@_ == 1) {
        my $option = lc($_[0]);
        return (defined($valid_options{$option})
                ? $self->{config}->{$option}
                : undef);
    }
    #
    # Otherwise, treat this as actually making changes.
    #
    my %settings = ((ref($_[0]) eq 'HASH') ? %{$_[0]} : @_);

    for my $key (keys(%settings)) {
        my $value = $settings{$key};
        $key = lc($key);
        if (defined($valid_options{$key})) {
            $self->{config}->{$key} = $value;
        }
    }
}

sub new {
    my ($class, @parameters) = @_;
    my $self = bless({}, ref($class) || $class);

    if (! @parameters) {
        croak('No config file given');
    }
    my $cfh = gensym();
    my $cfile = $parameters[0];
    open($cfh, "<$cfile") or croak("Error accessing config file '$cfile'");
    my @clines = <$cfh>;
    close($cfh);
    $self->{_rawfile} = \@clines;
    $self->{_test} = {};
    $self->{_filter} = {};
    $self->{_block} = [];

    my $workfile = [ @clines ];
    my $position = 0;
    while (my $block = $self->_getblock($workfile, \$position)) {
        push(@{$self->{_block}}, $block);
        my $type = $block->{type};
        my $name = $block->{fields}->{name};
        my $firstline = $block->{startline};
        if ($type !~ /^(?:test|filter)$/) {
            carp("Unrecognised block type '$type' at line $firstline");
        }
        elsif (! $name) {
            carp("Unnamed $type at line $firstline");
        }
        elsif ($type eq 'test') {
            $self->{_test}{$name} = $block;
        }
        elsif ($type eq 'filter') {
            $self->{_filter}{$name} = $block;
        }
        else {
            croak("Huh?");
        }
    }
    return $self;
}

#    my $result = {};
#    my @segment;
#    my $segtype;
#    my $startline;
#    my $storing = 0;
#    for (my $linenum = 1; $linenum <= @clines; $linenum++) {
#        my $cline = $clines[$linenum - 1];
#        chomp($cline);
#        $cline =~ s/^\s*#.*//;
#        $cline =~ s/^\s*(.*)?\s*$/$1/;
#        next if (! $cline);
#
#        if ($cline =~ /^(\[[^]]+\])$/) {
#            if ($storing) {
#                $storing = 0;
#                print join("\n", @segment) . "\n------\n";
#                my $type = lc($segtype);
#                if (! defined($sectionmap->{$type})) {
#                    carp("Don't know how to handle '$type' section "
#                         . "starting at line $startline");
#                    @segment = ();
#                }
#                else {
#                    $type = $sectionmap->{$type};
#                    my $object;
#                    eval("\$object = new $type;");
#                    $object->import(@segment);
#                    push(@{$result->{$type}}, $object);
#                }
#                @segment = ();
#                $startline = $linenum;
#            }
#            else {
#                $storing = 1;
#            }
#                $segtype = $1;
#        }
#        elsif ($storing) {
#            push(@segment, $cline);
#        }
#    }
#    $self->{sections} = $result;
#    return $self;
#}

#
# Passed an array of input lines, read to the first block, and then
# gobble it.
#
sub _getblock {
    my $self = shift;
    my $input = $_[0];
    my $lcounter = $_[1];

    my $linenum = ${$lcounter};
    my $line;
    my $found = 0;
    while ($line = $self->_getline($input, undef, \$linenum)) {
#        print "got line '$line'\n";
        last if (($line =~ /^\s*\[(\S+)\]/) && ($found = 1));
    }
    $line =~ /^\s*\[(\S+)\]/ if (defined($line));
    if (! $found) {
#        print "No block found.\n";
        return undef;
    }
    my $type = $1;
    my $block = new ReadConfig::Block;
    $block->{type} = $type;
    $block->{startline} = $linenum;
    while ($line = $self->_getline($input, undef, \$linenum)) {
        if ($line =~ /^\s*\[\S+\]/) {
            $self->_ungetline($input, $line);
            $linenum--;
            last;
        }
        my ($key, $value) = split(/\s*=\s*/, $line, 2);
        $block->set1($key, $value);
    }
    $block->{stopline} = $linenum;
    ${$lcounter} = $linenum;
    return $block;
}

#
# Passed a reference to an array, get the next complete line from it.
#
# ->_getline($aref [, $flagref [, $startlineref ] ])
#
sub _getline {
    my $self = shift;
    if ((! @_) || (ref($_[0]) ne 'ARRAY')) {
        croak(__PACKAGE__ . "::_getline called without an array reference\n");
        return undef;
    }
    my $input = $_[0];
    my $flags = { linecommentstring  => '#',
                  continuationstring => '\\',
                  ignoreblanklines   => 1,
                  ignorecomments     => 1,
                  collapsewhitespace => 1,
                };
    if (defined($_[1]) && (ref($_[1]) eq 'HASH')) {
        for my $k (keys(%{$_[1]})) {
            $flags->{lc($k)} = $_[1]{$k};
        }
    }
    my $linenum;
    if (defined($_[2]) && (ref($_[2]) eq 'SCALAR')) {
        $linenum = $_[2];
    }
    while (my $line = shift(@{$input})) {
        ${$linenum}++ if (defined($linenum));
        my $edited = $line;
        if ($flags->{ignorecomments}
            && (my $linecomment = $flags->{linecommentstring})) {
            $edited =~ s/${linecomment}.*//;
        }
        $edited =~ s/^\s+//;
        $edited =~ s/\s+$// if ($flags->{collapsewhitespace});
        next if ($flags->{ignoreblanklines} && ($edited =~ /^\s*$/));

        my $contin = $flags->{continuationstring};
        if ($contin) {
            my $clen = length($contin);
            if (substr($edited, -$clen) eq $contin) {
                $edited = substr($edited, 0, length($edited) - $clen);
                $edited .= $self->_getline($input, $flags, $linenum);
            }
        }
        return $edited;
    }
}

#
# Put something back on the front of a list.
#
sub _ungetline {
    my $self = shift;
    my $aref = shift;
    unshift(@{$aref}, @_);
}

#*** TODO: bring in continuation-handling code from.. which file was it again?

1;

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# c-basic-offset: 4
# End:
#
