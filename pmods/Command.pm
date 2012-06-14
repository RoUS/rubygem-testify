package CommandHelp;

sub new {
    my ($class, @parameters) = @_;
    my $self = bless({}, ref($class) || $class);
    if (@parameter) {
        $self->topic(@parameters);
    }
    return $self;
}

sub topic {
    my $self = shift;
    my $topic = shift;
    $self->{topic} = $topic;
    if (@_) {
        $self->node($topic, @_);
    }
}

sub node {
    my $self = shift;
    my $node = shift;
    if (@_ > 1) {
        #
        # Adding a subtopic
        #
        $self->{node}->{$node} = $_[0];
    }
    return $self->{node}->{$node} || undef;
}

1;

package Command;

use strict;
use vars qw( $AUTOLOAD $VERSION @verbs );

use Carp;
use Data::Dumper;
use Expect;
use Fcntl;
use File::Path;
use File::Spec::Functions;
use Filter;
use SDBM_File;
use Symbol;
use Text::Abbrev;
use Text::ParseWords;
use Text::Quote;

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
}

my $help;
my @verbs = qw(add
               compare
               create
               delete
               exit
               help
               list
               modify
               quit
               remove
               run
               show
               update
              );
my $verbs = abbrev @verbs;
my $topics = abbrev @verbs;
my @nouns = qw(benchmark
               filter
               test
              );
my $nouns = abbrev @nouns;
my $arg_run = abbrev qw(filter
                        test
                       );
my $subs = {'add'    => \$nouns,
            'create' => \$nouns,
            'delete' => \$nouns,
            'help'   => \$topics,
            'list'   => \$nouns,
            'remove' => \$nouns,
            'run'    => \$arg_run,
           };

my $verb;
my $command;
my $noun;

sub AUTOLOAD {
    my $self = shift;
    my ($method) = $AUTOLOAD;

    $method =~ s/.*:://;

    return if ($method eq 'DESTROY');

    my $verb;
    my $xl = $self->{config}->{localiser};
    my $msg;
    ($verb = $method) =~ s/^cmd_//;
    if  (grep(/^$verb$/, @verbs)) {
        $msg = $xl->lookup('_unimplmented_command');
    }
    else {
        $msg = $xl->lookup('_unknown_command');
    }
    carp(sprintf($msg, $verb));
    $self->status(1);
    return;
}

#
# Just for cleaning up..
#
sub DESTROY {
    my $self = shift;
    #
    # We don't use the closefile() method because we don't care about
    # error handling at this point.  If the close fails, there's not
    # much we can do about it.
    #
    for (keys(%{$self->{filehandles}})) {
        close($self->{filehandles}->{$_});
        delete($self->{filehandles}->{$_});
    }
    $self->restore_argv() if (defined($self->{ARGV}) && @{$self->{ARGV}});
}

#
# Open a file (if possible) and add it to the list, or else return the
# existing filehandle if it's already open.  This allows us to close
# them as part of our destruction.
#
sub openfile {
    my $self = shift;
    my ($name, $file) = @_;

    $self->status(0);
    my $fh;
    my $fhandles = $self->{filehandles};

    if ($fh = $fhandles->{$name}->{handle}) {
        if ($file ne $fhandles->{$name}->{file}) {
            carp("File identifier '$name'already in use for another file");
            return undef;
        }
        return $fh;
    }
    $fh = gensym();
    open($fh, $file) or do {
        $self->status($!);
        carp("Error opening file '$file': $!");
        return undef;
    };
    $fhandles->{$name}->{handle} = $fh;
    $fhandles->{$name}->{file} = $file;
    return $fh;
}

sub closefile {
    my $self = shift;
    my ($fid) = @_;

    $self->status(0);
    my $type = ref($fid);
    my $fhandles = $self->{filehandles};
    my $key;
    my $fh;

    for (keys(%{$fhandles})) {
        if (($type eq 'GLOB') && ($fid == $fhandles->{$_}->{handle})) {
            $fh = $fid;
            $key = $_;
            last;
        }
        elsif ((! $type) && ($fid == $fhandles->{$_}->{name})) {
            $fh = $fhandles->{$_}->{handle};
            $key = $_;
            last;
        }
    }
    if (! $key) {
        carp("Request to close unopened file '$fid'");
        $self->status(1);
        return undef;
    }
    if (close($fh)) {
        delete($fhandles->{$key});
    }
    else {
        carp("Unable to close file '$fid': $!");
        $self->status($!);
    }
    return $self->status();
}

sub status {
    my $self = shift;
    my $was = $self->{status};
    if (@_) {
        $self->{status} = $_[0];
    }
    return $was;
}

sub new {
    my ($class, @parameters) = @_;
    my $self = bless({}, ref($class) || $class);
    $self->config(@parameters);
    $self->{quoter} = new Text::Quote;
    $self->status(0);
    $self->{filehandles} = {};
    $self->{help} = {};
    return $self;
}

sub config {
    my $self = shift;
    my %cfg = @_;
    for (keys(%cfg)) {
        my $ckey = $_;
        $ckey =~ s§^[^-\w]+§§;
        $ckey = lc($ckey);
        $self->{config}->{$ckey} = $cfg{$_};
    }
    $self->status(0);
    return;
}

sub assemble_safely {
    my $self = shift;
    my @result;
    for (@_) {
        my @words = parse_line('\s+', 0, $_);
        if (@words > 1) {
            push(@result, $self->{quoter}->quote_simple($_));
        }
        else {
            push(@result, $_);
        }
    }
    return join(' ', @result);
}

sub save_argv {
    my $self = shift;
    $self->{ARGV} = [ @ARGV ];
}

sub restore_argv {
    my $self = shift;
    @ARGV = @{$self->{ARGV}};
    $self->{ARGV} =  [ ];
}

sub parse {
    my $self = shift;
    my ($cmdline, @tokens) = @_;
    my $xl = $self->{config}->{localiser};

    $self->status(0);
    if (@tokens > 0) {
        $cmdline .= ' ' . $self->assemble_safely(@tokens);
    }
    $self->{raw_commandline} = $cmdline;
    $self->save_argv();
    @ARGV = parse_line('\s+', 0, $cmdline);
    for (@ARGV) {
        print "<$_>\n";
    }

    $verb = shift(@ARGV);
    if (defined(my $fullverb = $verbs->{lc($verb)})) {
        $verb = $fullverb;
    }
    $command = $verb;
    $self->{_verb} = $verb;
    $self->{args} = [ @ARGV ];
    print "command: '" . $self->{raw_commandline} . "'\n";

    my $verb_method = "cmd_$verb";
    $self->$verb_method(@{$self->{args}});

    if (0) {
        if (defined($subs->{$verb})) {
            $noun = shift;
            if ($verb ne 'help') {
                if (! $noun) {
                    my $text = $xl->lookup('_badsyntax', '_nohelp');
                    $text = sprintf($text, $command);
                    print STDERR "$text\n";
                    $self->status(1);
                    return undef;
                }
                if (! defined($nouns->{lc($noun)})) {
                    print STDERR "Unrecognised command '$verb $noun'\n";
                    $self->status(1);
                    return undef;
                }
                $noun = $nouns->{lc($noun)};
                $command .= " $noun";
            }
        }
    }
}

sub verb {
    my $self = shift;
    return $self->{_verb};
}

sub load_help {
    my $self = shift;
    my $topic = shift;
    my $xl = $self->{config}->{localiser};
    my $text = $xl->lookup($topic);
    return undef if (! $text);
    my $ch = new CommandHelp($topic);
    #
    # Right, now break it into pieces if necessary.
    #
    my @lines = split(/\r?\n/, $text);
    if (grep(/^-/, @lines)) {
        #
        # Whoops, subtopics..
        #
        my $key = $topic;
        my @text;
        for (@lines) {
            if ($_ =~ /^-(.*)/) {
                if (@text) {
                    $ch->node($key, join("\n", @text));
                    @text = ();
                }
                $key = $1;
            }
            else {
                push(@text, $_);
            }
        }
    }
    else {
        $ch->topic($topic, $text);
    }
    $self->{help}->{$topic} = $ch;
    return $ch;
}

sub get_help {
    my $self = shift;
    my $topic = shift;
    my $default = shift || '_nohelp';
    my $text;
    my $xl = $self->{config}->{localiser};
    $text = $xl->lookup($topic, $default);
    if (@_ && ($text =~ /%/)) {
        $text = sprintf($text, @_);
    }
    return $text;
}

#
# Methods for actually handling commands
#

#
# All of the 'get out of here' verbs are fronts for 'quit'.  If we
# ever go to a changes-pending commit/revert model, we'll need to
# differentiate them.  'quit' usually means 'exit without saving
# changes.'
#
sub cmd_exit {
    goto &cmd_quit;
}

#
# This whole help system could use some serious revamping.  It owes some
# of its mechanisms to the VMS V1 help system, but it's excessively
# simplified to only providing help for top-level verbs.
#
# Plus, extracting the help into a separately maintainable set of
# files rather than embedding them in here might be a good idea..
# plus allow for translations.
#
sub cmd_help {
    my $self = shift;
    my ($command) = @_;

    $self->status(0);
    
    if (! $command) {
        #
        # Generic help, not for a specific command..
        #
        $command = 'help';
    }

    my $ftopic = $topics->{lc($command)};
    my %topics = map { $_ => 1 } values(%{$topics});
    if (defined($ftopic)) {
        print "HELP" . ($ftopic eq 'help' ? '' : " $ftopic") . "\n";
        print $self->get_help("help_$ftopic", undef, $ftopic);
    }
    elsif (grep(/^$command/, keys(%topics))) {
        print $self->get_help('_ambiguous', undef, $command);
    }
    else {
        my @topics = sort(keys(%topics));
        print " Help is available on the following topics:\n\n";
        for (@topics) {
            print "    $_\n";
        }
    }
}

sub cmd_quit {
    my $self = shift;
    $self->status(0);
}
    
sub cmd_run {
    my $self = shift;
    my (@tokens) = @_;

    $self->status(0);
}

sub cmd_list {
    my $self = shift;
    my $xl = $self->{config}->{localiser};
    my $cfg = $self->{config}->{config};
    my $what = lc($_[0]);
    #
    # Handle the special case of plurals, which only work for this command
    #
    $what =~ s/s$// if (($what =~ /s$/) && (! defined($nouns->{$what})));
    if (! grep(/^$what$/, keys(%{$nouns}))) {
        #
        # Have no idea what it is..
        #
        my $msg = $xl->lookup('_unknown_item');
        carp(sprintf($msg, $_[0]));
        $self->status(1);
        return;
    }
    $what = $nouns->{$what};
    #
    # Now see if there's a pattern we should match
    #
    my @args = @_;
    print '<' . join('> <', @args) . ">\n";
    my $items;
    my $match = ((@_ > 1) && $_[1]);
    my $condition = 1;
    for (@{$cfg->{_block}}) {
        $condition = ($_->{fields}->{name} =~ qr{$_[1]}) if ($match);
        $items->{$_->{fields}->{name}} = $_
            if (($_->{type} =~ /^$what$/i) && $condition);
    }
    if ($items) {
        for (sort(keys(%{$items}))) {
            print $items->{$_}->{fields}->{name} . "\n";
        }
    }
    else {
        my $msg = $xl->lookup($ match ? '_nomatch' : '_none');
        printf($msg, $nouns->{$what}, $match ? $_[1] : undef);
    }
    my $ch = $self->load_help('add');
    print Dumper($ch);
    $self->status(0);
}

1;

__DATA__
#
# Start each topic with its name preceded by '&' in column one.
#
&add
&compare
&create
&delete
&help
By itself, the 'help' command simply tells you for what topics
help is available.  Each topic can be viewed by including it on
the command line, such as 'help add'.

If the topic string is ambiguous, all potentially matching
topics are displayed.
&modify
&quit
Synonym for 'exit'.
&remove
Synonym for 'delete'.
&run
Execute a test.

Syntax:
    run <testname>
&show
__END__
#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# c-basic-offset: 4
# End:
#
