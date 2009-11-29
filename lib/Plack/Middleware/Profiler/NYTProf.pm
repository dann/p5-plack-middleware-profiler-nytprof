package Plack::Middleware::Profiler::NYTProf;
use strict;
use warnings;
use strict;
use warnings;
use parent qw(Plack::Middleware);

use Time::HiRes;
use Devel::NYTProf;

use constant PROFILE_ID => 'psgix.profiler.nytprof.reqid';

our $VERSION = '0.01';

sub call {
    my ( $self, $env ) = @_;
    $self->start($env);
    my $res = $self->app->($env);
    $self->report($env);
    $self->end($env);
    $res;
}

sub start {
    my ( $self, $env ) = @_;
    my $id = Time::HiRes::gettimeofday;
    $env->{PROFILE_ID} = $id;
    DB::enable_profile("/tmp/nytprof.$id.out");
}

sub end {
    DB::disable_profile();
}

sub report {
    my ( $self, $env ) = @_;
    if ( my $id = $env->{PROFILE_ID} ) {
        DB::enable_profile("/tmp/nyprof.null.out");
        DB::disable_profile();
        system "nytprofhtml", "-f", "/tmp/nytprof.$id.out", "--open";
    }
}

sub DESTROY {
    DB::finish_profile();
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Profiler::NYTProf -

=head1 SYNOPSIS

  use Plack::Middleware::Profiler::NYTProf;

=head1 DESCRIPTION

Plack::Middleware::Profiler::NYTProf is


=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/

=head1 CONTRIBUTORS

Many thanks to:


=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
