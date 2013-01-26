package Plack::Middleware::Profiler::NYTProf;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
    enable_profiler
    enable_reporting
    env_nytprof
    generate_profile_id
    output_dir
    report_file_name
    nullfile_name
    before_profile
    after_profile
);
use File::Spec;
use Time::HiRes;

use constant PROFILE_ID => 'psgix.profiler.nytprof.reqid';

our $VERSION = '0.02';

sub prepare_app {
    my $self = shift;

    $self->_setup_enable_reporting;
    $self->_setup_report_file_paths;
    $self->_setup_profiling_hooks;
    $self->_setup_profile_id;
    $self->_setup_enable_profiler;
    $self->_setup_profiler if $self->enable_profiler->();
}

sub _setup_profiler {
    my $self = shift;
    $ENV{NYTPROF} = $self->env_nytprof || 'start=no';
    require Devel::NYTProf;
}

sub _setup_report_file_paths {
    my $self = shift;
    $self->_setup_output_dir;
    $self->_setup_report_file_name;
    $self->_setup_nullfile_name;
}

sub _setup_enable_reporting {
    my $self = shift;
    $self->enable_reporting(1) unless $self->enable_reporting;
}

sub _setup_enable_profiler {
    my $self = shift;
    $self->enable_profiler( sub {1} ) unless $self->enable_profiler;
}

sub _setup_output_dir {
    my $self = shift;
    $self->output_dir( sub {'.'} ) unless is_code_ref( $self->output_dir );
}

sub _setup_profile_id {
    my $self = shift;
    $self->generate_profile_id( sub { return $$ . "-" . Time::HiRes::gettimeofday; } )
        unless is_code_ref( $self->generate_profile_id );
}

sub _setup_report_file_name {
    my $self = shift;
    $self->report_file_name(
        sub { my $id = $_[1]->{PROFILE_ID}; return "nytprof.$id.out"; } )
        unless is_code_ref( $self->report_file_name );
}

sub _setup_nullfile_name {
    my $self = shift;

    $self->nullfile_name('nytprof.null.out') unless $self->nullfile_name;
}

sub _setup_profiling_hooks {
    my $self = shift;
    $self->before_profile( sub { } )
        unless is_code_ref( $self->before_profile );
    $self->after_profile( sub { } )
        unless is_code_ref( $self->after_profile );

}

sub call {
    my ( $self, $env ) = @_;

    if ( $self->enable_profiler->( $self, $env ) ) {
        $self->before_profile->( $self, $env );
        $self->start_profiling($env);
    }

    my $res = $self->app->($env);

    if ( $self->enable_profiler->( $self, $env ) ) {
        $self->stop_profiling($env);
        $self->report($env) if $self->enable_reporting;
        $self->after_profile->( $self, $env );
    }

    $res;
}

sub start_profiling {
    my ( $self, $env ) = @_;

    $env->{PROFILE_ID} = $self->generate_profile_id->( $self, $env );
    DB::enable_profile( $self->report_file_path($env) );
}

sub stop_profiling {
    DB::disable_profile();
}

sub report {
    my ( $self, $env ) = @_;

    return unless $env->{PROFILE_ID};

    DB::enable_profile( $self->nullfile_path );
    DB::disable_profile();

    system "nytprofhtml", "-f", $self->report_file_path($env), "--open";
}

sub report_file_path {
    my ( $self, $env ) = @_;

    return File::Spec->catfile(
        $self->output_dir->( $self, $env ),
        $self->report_file_name->( $self, $env )
    );
}

sub nullfile_path {
    my ( $self, $env ) = @_;

    return File::Spec->catfile( $self->output_dir->( $self, $env ),
        $self->nullfile_name );
}

sub is_code_ref {
    my $ref = shift;
    return ( ref($ref) eq 'CODE' ) ? 1 : 0;
}

sub DESTROY {
    DB::finish_profile();
}

1;

__END__


=encoding utf-8

=head1 NAME

Plack::Middleware::Profiler::NYTProf - Middleware for Profiling a Plack App

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'Profiler::NYTProf';
        [ '200', [], [ 'Hello Profiler' ] ];
    };

=head1 DESCRIPTION

Plack::Middleware::Profiler::NYTProf helps you to get profiles of Plack App.

=head1 OPTIONS

NOTE that some options expect a code reference. Maybe, you feel it complicated. However that will enable to control them programmably. It is more useful to your apps.

=over 4

=item enable_profile

default

    sub { 0 }

This option can receive both scalar and code reference.
If you want to turn on the profile, you have to specify this option: 1 or code ref that return TRUE value.

=item env_nytprof

default

    'start=no'

This option set to $ENV{NYTPROF}. See L<Devel::NYTProf>: NYTPROF ENVIRONMENT VARIABLE section. Actualy, Plack::Middleware::Profiler::NYTProf loads Devel::NYTProf lazy for setting $ENV by option.

=item profile_dir

directory for files about profile.

default

    sub { '.' }

=item profile_file

file name about profile

default

    sub { my $id = $_[1]->{PROFILE_ID}; return "nytprof.$id.out"; }

=item profile_id

ID for every profile

default

    "$$\.". time(); # if you have Time::HiRes, use T::HR::gettimeofday instead.

=item nullfile

file name of dummy profile 

default

    'nytprof.null.out'

=item after_profile

proccess that execute after profile

default

    sub {}

check C<examples> dir of this distribution.

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-plack-middleware-profiler-nytprof

=head1 CONTRIBUTORS

Many thanks to: bayashi

=head1 AUTHOR

Takatoshi Kitano E<lt>kitano.tk {at} gmail.comE<gt>
Dai Okabayashi

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
