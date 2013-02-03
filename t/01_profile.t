use strict;
use Plack::Middleware::Profiler::NYTProf;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use lib './t/lib';
use ProfilerNYTProfUtil;

my $app = Plack::Middleware::Profiler::NYTProf->wrap(
    base_app(),
    enable_reporting => 0,
);

test_psgi $app, sub {
    my $cb  = shift;
    my $at_start = time();
    my $res = $cb->( GET "/" );
    my $at_end = time();

    is $res->code, 200;

    is -e "nytprof.out", 1, "exists nytprof.out";
    unlink "nytprof.out";

    my $regex = qr/nytprof\.\d+\-(\d+)\.\d+\.out/;
    for my $file ( glob("nytprof*.out") ) {
        like $file, $regex, "exists result file: $file";
        my ($time) = ($file =~ m!$regex!);
        ok ($time >= $at_start && $time <= $at_end), "result time";
    }
};

unlink glob("nytprof*.out");

done_testing;
