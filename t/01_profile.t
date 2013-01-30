use strict;
use Plack::Middleware::Profiler::NYTProf;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    return [ '200', [ 'Content-Type' => 'text/plain' ], ["Hello World"] ];
};
$app = Plack::Middleware::Profiler::NYTProf->wrap( $app,
    enable_reporting => 0 );

test_psgi $app, sub {
    my $cb  = shift;
    my $res = $cb->( GET "/" );
    is $res->code, 200;
};

unlink glob("nytprof*.out");

done_testing;
