use strict;
use Plack::Middleware::Profiler::NYTProf;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use t::Util;

subtest 'Change report_dir location' => sub {
    my $result_dir = tempdir();
    my $report_dir = tempdir();

    my $app = Plack::Middleware::Profiler::NYTProf->wrap(
        simple_app(),
        env_nytprof => "start=no:addpid=0:file="
            . path( $result_dir, "nytprof.out" ),
        enable_reporting => 1,
        report_dir       => sub {$report_dir},
    );

    isnt -e path( $report_dir, "index.html" ), 1,
        "Doesn't exists report directory before profiling";

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );

        is $res->code, 200, "Response is returned successfully";

        is -e path( $result_dir, "nytprof.out" ), 1, "Exists nytprof.out";
        is -e path( $report_dir, "index.html" ),  1, "Exists the report file";
        isnt -d "report", 1, "Doesn't exist default report directory";
    };

    unlink glob("nytprof*.out");
};

subtest 'Change profiling_result_dir location and output filename' => sub {
    my $result_dir      = tempdir();
    my $result_filename = $$;

    my $app = Plack::Middleware::Profiler::NYTProf->wrap(
        simple_app(),
        env_nytprof => "start=no:addpid=0:file="
            . path( $result_dir, "nytprof.out" ),
        profiling_result_dir       => sub {$result_dir},
        profiling_result_file_name => sub {"nytprof.$result_filename.out"},
        enable_reporting           => 0
    );

    isnt -e path( $result_dir, "nytprof.$result_filename.out" ), 1,
        "Doesn't exists profile before profiling";

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );

        is $res->code, 200, "Response is returned successfully";

        is -e path( $result_dir, "nytprof.$result_filename.out" ), 1,
            "exists profile";
        isnt -e "nytprof.out", 1, "Doesn't exist nytprof.out";

        isnt -e path( "report", "index.html" ), 1,
            "Doesn't exist report file";
    };

    unlink glob("nytprof*.out");
};

done_testing;
