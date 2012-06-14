package ReadConfig::Block;

my $ppfields = {
                name        => 'Name',
                description => 'Description',
                location    => 'Location',
                readlines   => 'ReadLines',
               };

sub new {
    my ($class, @parameters) = @_;
    my $self = bless({}, ref($class) || $class);

    return $self;
}

sub as_string {
    return serialise(@_);
}

sub serialise {
    my $self = shift;
    my $result = '[' . $self->{type} . "]\n";
    my $fields = $self->{fields};
    if (defined($fields->{name})) {
        $result .= sprintf("    Name = %s\n", $fields->{name});
    }
    if (defined($fields->{description})) {
        $result .= sprintf("    Description = %s\n", $fields->{description});
    }
    for my $field (sort(keys(%{$fields}))) {
        next if ($field =~ /^(?:name|description)$/i);
        my $name = $ppfields->{$field} || $field;
        $result .= sprintf("    %s = %s\n", $name, $fields->{$field});
    }
    return $result;
}

sub set1 {
    my $self = shift;
    my ($arg, @args) = @_;
    $arg = lc($arg);
    my $value;
    if (@args == 0) {
        $value = undef;
    }
    elsif (@args == 1) {
        $value = $args[0];
    }
    else {
        $value = [ @args ];
    }
    my $old;
    if (defined($self->{fields}->{$arg})) {
        $old = $self->{fields}->{$arg};
    }
    $self->{fields}->{$arg} = $value;
#    print "[block] setting '$arg'\n";
    return $old;
}

1;
