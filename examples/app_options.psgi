use Plack::Builder;

my $app = sub {
    my $env = shift;
    return [ '200', [ 'Content-Type' => 'text/plain' ], [ "Hello World $$" ] ];
};

builder {
    # you should execute 'mkdir /tmp/profile' before invoking this PSGI app;
    enable_if { 1 } 'Profiler::NYTProf',
        enable_profile       => sub { $$ % 2 == 0 },
        env_nytprof          => 'start=no:addpid=0:file=/tmp/profile/nytprof.out',
        profiling_result_dir => sub { '/tmp/profile' },
        enable_reporting     => 1;
    $app;
};

=pod

    check the report.

    $ plackup -MPlack::App::Directory -e 'Plack::App::Directory->new({root => "./report"})->to_app'

=cut