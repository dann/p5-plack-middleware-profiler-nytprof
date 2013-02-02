use Mojolicious::Lite;
use Plack::Builder;

get '/' => 'index';

builder {
  enable "Profiler::NYTProf",
    # Add blocks=0 and slowops=0 to reduce performance penalty
    env_nytprof          => 'start=no:addpid=0:blocks=0:slowops=0:file=/tmp/profile/nytprof.out',
    profiling_result_dir => sub { '/tmp' },
    # Don't generate HTML report for production. Generate only NYTProf profiling output.
    enable_reporting     => 0;
 
  app->start;
};

__DATA__

@@ index.html.ep
<html><body>Hello World</body></html>
