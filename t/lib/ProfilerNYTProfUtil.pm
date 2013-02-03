package ProfilerNYTProfUtil;
use strict;
use warnings;
use File::Temp qw//;
use File::Spec;

sub import {
    my $caller = caller;

    for my $func (qw/base_app tempdir path/) {
        no strict 'refs';
        *{"${caller}::$func"} = \&{$func};
    }
}

sub base_app {
    return sub {
        my $env = shift;
        return [ '200', [ 'Content-Type' => 'text/plain' ], ["Hello World"] ];
    };
}

sub tempdir {
    return File::Temp::tempdir(CLEANUP => 1);
}

sub path {
    File::Spec->catfile(@_);
}

1;
