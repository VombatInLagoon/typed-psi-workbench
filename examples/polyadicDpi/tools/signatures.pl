#!/usr/bin/perl

#
# signature Name =
# sig
#   ...
#   include SIG
#   ...
#   structure S: SIG
#   ...
# end
#

sub sweep_comments {
    my $s = shift;

    # obviously does not work for the nested comments
    $s =~ s/\(\* (.*?) \*\)//sxg;
    $s;
}

sub clean_body {
    my $s = shift;

    $s =~ s/\n+/\n/g;
    $s = sweep_comments $s;
    $s;
}

sub scrape_sig {
    my $s = shift;
    my @res = ();

    while ($s =~ /signature \s* (\w+) \s* = \s*
                  sig \s+
                    (.*?)
                  \s+
                  end
                  /xsg) {
        
        push @res, {name => $1, body => clean_body $2};
    }
    @res
}

sub includes {
    local $_ = @_[0];

    /include \s+ (\w+)/xsg
}

sub structures {
    my $s = shift;

    my @res = ();
    while ($s =~ /structure \s+ (\w+) \s* : \s* (\w+)/xsg) {
        push @res, {name => $1, sig => $2}
    }
    @res
}


sub graphviz {
    my $s = shift;

    my @sigs = scrape_sig $s;

    print "digraph {\n";
    for (@sigs) {
        my $label = $_->{body};
        my $n = $_->{name};
        $label =~ s/\n/\\l/g;
        $label .= '\l';
        print '"', $_->{name}, '"', " [labeljust=\"l\",shape=box, label=\"$n\\n\\n$label\"];\n\n"
    }

    # includes
    for (@sigs) {
        my @incs = includes ($_->{body});
        my $n = $_->{name};

        for (@incs) {
            print "\"$n\" -> \"$_\" [label=\"include\"]\n";
        }
    }
    print "\n\n";


    # structures
    for (@sigs) {
        my @strs = structures ($_->{body});
        my $n = $_->{name};

        for (@strs) {
            my $sn = $_->{sig};
            print "\"$n\" -> \"$sn\" [label=\"structure\"]\n";
        }
    }

    print "}\n";
}


local $/; # slurp mode
my $s = <>;
graphviz $s;


