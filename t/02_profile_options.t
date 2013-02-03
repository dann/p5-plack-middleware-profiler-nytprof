use strict;
use Plack::Middleware::Profiler::NYTProf;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use lib './t/lib';
use ProfilerNYTProfUtil;

{
    my $result_dir      = tempdir();
    my $result_filename = $$;
    my $report_dir      = tempdir();

    my $app = Plack::Middleware::Profiler::NYTProf->wrap(
        base_app(),
        env_nytprof          => "start=no:addpid=0:file=". path($result_dir,"nytprof.out"),
        profiling_result_dir => sub { $result_dir },
        profiling_result_file_name => sub { "nytprof.$result_filename.out" },
        enable_reporting     => 1,
        report_dir           => sub { $report_dir },
    );

    # there aren't still files or dirs
    isnt -e path($result_dir, "nytprof.$result_filename.out"), 1, "no exists profile";
    isnt -e path($report_dir, "index.html"),                   1, "no exists report";

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );

        is $res->code, 200;

        is -e path($result_dir, "nytprof.out"),                  1, "exists nytprof.out";
        is -e path($result_dir, "nytprof.$result_filename.out"), 1, "exists profile";
        is -e path($report_dir, "index.html"),                   1, "exists report";

        isnt -e "nytprof.out", 1, "no exists nytprof.out";
        isnt -d "report",      1, "no exists report";
    };
}

done_testing;
