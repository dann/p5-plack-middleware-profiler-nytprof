use Plack::Builder;

my $app = sub {
    my $env = shift;
    use YAML;
    use Moose;
    return [ '200', [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
};

builder {
    enable "Plack::Middleware::Profiler::NYTProf";
    $app;
};
