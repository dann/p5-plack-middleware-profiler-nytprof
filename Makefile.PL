use inc::Module::Install;
name 'Plack-Middleware-Profiler-NYTProf';
all_from 'lib/Plack/Middleware/Profiler/NYTProf.pm';

requires(
    'Plack'          => 0,
    'Devel::NYTProf' => 0,
    'Time::HiRes'    => 0,
);
test_requires(
    'Test::More'                   => 0,
    'Test::LoadAllModules'         => 0,
    'Module::Install::AuthorTests' => 0,
    'File::Temp'                   => 0,
    'File::Spec'                   => 0,
);
use_test_base;
auto_include;
WriteAll;
