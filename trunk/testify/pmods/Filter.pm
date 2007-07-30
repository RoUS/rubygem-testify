package Filter;
#
use strict;
use vars qw($VERSION);
use Expect;
use IO::Stty;
use Data::Dumper;
use Convert::ASCIInames;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    use vars qw (%valid_options @valid_options);
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
    @valid_options = qw( Name
                         Description
                         Location
                         ReadLines
                         Sentinel
                         Debug
                         );
    %valid_options= map { lc($_) => 1} @valid_options;
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
    my ($class, %parameters) = @_;
    my $self = bless({}, ref($class) || $class);

    $self->config(Location  => 'filters/',
                  ReadLines => 'all',
                  Sentinel  => sprintf('\n\%03oEOT\%03o',
                                       ASCIIordinal('SSA'),
                                       ASCIIordinal('ESA')));
    $self->config(%parameters) if (%parameters);
    if (my $name = $self->config('name')) {
        $self->{_file} = $self->config('Location') . $name;
    }
    $self->{_valid} = ($self->{_file} && (-r $self->{_file}));
    return $self;
}

#
# This import/export stuff should be in a common module, not defined
# per-package.
#
sub import {
    my $self = shift;
    my @lines;
    if (@_ == 1) {
        if (ref($_[0]) eq 'ARRAY') {
            @lines = @{$_[0]};
        }
        elsif (ref($_[0]) eq 'HASH') {
            return $self->config(%{$_[0]});
        }
        else {
            @lines = split(/\s*[\r\n]+\s*/, $_[0]);
        }
    }
    chomp(@lines);
    @lines = grep(!/(?:^\s*#|^$)/, @lines);

    my $started = 0;
    for my $line (@lines) {
        $line =~ s/^\s*(.*)?\s*$/$1/;
        next if ((! $started) && ($line !~ /^\s*\[filter\]\s*$/i));
        if ($line =~ /^\s*\[filter\]\s*$/i) {
            last if ($started);
            $started = 1;
            next;
        }
        my ($kw, $value) = split(/\s*=\s*/, $line, 2);
        $self->config($kw, $value);
    }
}

sub export {
    my $self = shift;
    my ($dest) = @_;

    my @result = qw( [filter] );
    for my $kw (@valid_options) {
        my $value = $self->config($kw);
        next if (! $value);
        push(@result, sprintf('    %s = %s', $kw, $value));
    }
    my $result = join("\n", @result) . "\n";
    if (defined($dest) && (ref($dest) eq 'GLOB')) {
        print $dest $result;
    }
    return $result;
}

sub run {
    my $self = shift;
    my ($isource) = @_;

    return undef if (! $self->{_valid});
    my $file = $self->{_file};
    my $sentinel = $self->config('sentinel');
    my $echo_back;
    eval("\$echo_back = qq§$sentinel§;");
    my $command = 'perl ';
    $command .= '-p ' if ($self->config('ReadLines') ne 'all');
    $command .= "-e 'eval(\"require(q§$file§);\"); "
        . "sub END { print qq§$sentinel\\n§; }'";
    print STDERR "command=$command\n";

    my $xp = new Expect;
    $xp->raw_pty(1);
    $xp->slave()->stty(qw(raw -echo));
    $xp->spawn($command);

    my @input;
    $isource = \*STDIN if (! defined($isource));
    my $itype = ref($isource);
    if ($itype eq 'GLOB') {
        #
        # It's a file handle; read it.
        #
        @input = <$isource>;
    }
    elsif ($itype eq 'ARRAY') {
        #
        # It's a reference to an array.
        #
        @input = @{$isource};
    }
    elsif ($itype eq '') {
        #
        # It's a string (we think).  If it was null, we would have turned
        # it into a glob.
        #
        push(@input, $isource);
    }
    push(@input, "$echo_back\n");
    print $xp @input;
    my @xp_status = $xp->expect(10,
                                '-re', qq{^(.*)?$sentinel});
    $xp->close();
    print Dumper(\@xp_status);
    my $result;
    if (! defined($xp_status[1])) {
        #
        # No error; pull the results out of the pattern match
        #
#        my @matches = $xp->matchlist();
#        print Dumper(\@matches);
#        $result = $matches[0];
        #
        # Well, that's what we *should* do, but it isn't working --
        # so yank it from the status array without understanding
        # why the trailing sentinel isn't being included.
        #
        $result = $xp_status[3];
    }
    else {
        #
        # Some sort of error; pull the output from the 'before match'
        # field.
        #
        $result = $xp_status[3];
    }
    return $result;
}

1;

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# c-basic-offset: 4
# End:
#
