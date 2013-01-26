use Plack::Builder;

my $app = sub {
    my $env = shift;
    use YAML;
    use Moose;
    return [ '200', [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
};

builder {
    # you should execute 'mkdir /tmp/profile' before invoking this PSGI app;
    enable_if { 1 } 'Profiler::NYTProf',
        enable_profile => sub { 1 },
        env_nytprof    => 'start=no:file=/tmp/profile/nytprof.out',
        profile_dir    => sub { '/tmp/profile' },
        after_profile  => sub {
            my ($self, $env) = @_;
            system(
                'nytprofhtml',
                '-f', $self->report_path($env),
                '-o', $self->profile_dir->(). '/nytprof',
                '--open'
            );
        };
    $app;
};
