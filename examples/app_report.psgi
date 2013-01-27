use Plack::Builder;
use Plack::App::File;

my $app = sub {
    my $env = shift;
    return [ '200', [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
};

builder {
    mount "/report" => Plack::App::File->new(root => "./report");
    mount "/" => $app;
};

