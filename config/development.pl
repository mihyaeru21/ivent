use File::Spec;
use File::Basename qw(dirname);
my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath = File::Spec->catfile($basedir, 'db', 'development.db');
+{
    'DBI' => [
        "dbi:mysql:dbname=dev_ivent", 'root', '<MY_PASS>',
        +{
            mysql_enable_utf8 => 1,
        }
    ],
};
