package Plack::Middleware::Profiler::NYTProf;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw/
    enable_profile
    env_nytprof
    profile_dir
    profile_file
    profile_id
    nullfile
    after_profile
/;
use File::Spec;
our $TIME_HIRES_AVAILABLE = undef;
BEGIN {
    eval { require Time::HiRes; };
    $TIME_HIRES_AVAILABLE = ($@) ? 0 : 1;
}
sub _gen_id {
    if ($TIME_HIRES_AVAILABLE) {
        return "$$\.". Time::HiRes::gettimeofday;
    }
    else {
        return "$$\.". time;
    }
}

use constant PROFILE_ID => 'psgix.profiler.nytprof.reqid';

our $VERSION = '0.01';

sub is_code {
    my $ref = shift;
    return (ref($ref) eq 'CODE') ? 1 : 0;
}

sub prepare_app {
    my $self = shift;

    if (ref($self->enable_profile) eq '' && $self->enable_profile) {
        $self->enable_profile(sub { 1 });
    }
    if ( !is_code($self->enable_profile) || !$self->enable_profile->() ) {
        $self->enable_profile(sub { 0 });
    }
    $self->enable_profile->() and do {
        $ENV{NYTPROF} = $self->env_nytprof || 'start=no';
        require Devel::NYTProf;
    };
    is_code($self->profile_dir)
        or $self->profile_dir(sub { '.' });
    is_code($self->profile_file)
        or $self->profile_file(
            sub { my $id = $_[1]->{PROFILE_ID}; return "nytprof.$id.out"; } );
    is_code($self->profile_id)
        or $self->profile_id(sub { _gen_id() });
    $self->nullfile
        or $self->nullfile('nytprof.null.out');
    is_code($self->after_profile)
        or $self->after_profile(sub {});
}

sub call {
    my ( $self, $env ) = @_;

    if ( $self->enable_profile->($self, $env) ) {
        $self->start($env);
    }

    my $res = $self->app->($env);

    if ( $self->enable_profile->($self, $env) ) {
        $self->report($env);
        $self->end($env);
    }

    $res;
}

sub start {
    my ( $self, $env ) = @_;

    $env->{PROFILE_ID} = $self->profile_id->($self, $env);
    DB::enable_profile( $self->report_path($env) );
}

sub end {
    DB::disable_profile();
}

sub report {
    my ( $self, $env ) = @_;

    if ($env->{PROFILE_ID}) {
        DB::enable_profile(
            File::Spec->catfile(
                $self->profile_dir->($self, $env),
                $self->nullfile
            )
        );
        DB::disable_profile();
        $self->after_profile->($self, $env);
    }
}

sub report_path {
    my ( $self, $env ) = @_;

    return File::Spec->catfile(
        $self->profile_dir->($self, $env),
        $self->profile_file->($self, $env)
    );
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
