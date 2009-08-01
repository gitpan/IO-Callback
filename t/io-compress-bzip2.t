# IO::Callback 1.00 t/io-compress-bzip2.t
# Check that IO::Callback inter-operates with IO::Compress::Bzip2

use strict;
use warnings;

use Test::More;
BEGIN {
    eval 'use IO::Compress::Bzip2 qw/bzip2/';
    plan skip_all => 'IO::Compress::Bzip2 required' if $@;

    eval 'use IO::Uncompress::Bunzip2 qw/bunzip2/';
    plan skip_all => 'IO::Uncompress::Bunzip2 required' if $@;

    plan tests => 6;
}
use Test::NoWarnings;

use Fatal qw/close/;
use IO::Callback;

sub is_bzip2ped ($$;$) {
    my ($gzgot, $want, $comment) = @_;

    my $got;
    bunzip2(\$gzgot, \$got) or die "bunzip2 failed";
    is( $got, $want, $comment );
}

my $test_data = "foo\n" x 100;

my $lines = 0;
my $coderef_read_fh = IO::Callback->new('<', sub {
    return if $lines++ >= 100;
    return "foo\n";
});

my $compressed;
ok bzip2($coderef_read_fh, \$compressed), "bzip2 from read coderef succeeded";
is_bzip2ped $compressed, $test_data, "bzip2 from read coderef correct";

my $got_close = 0;
my $got_data = '';
my $coderef_write_fh = IO::Callback->new('>', sub {
    my $buf = shift;
    if (length $buf) {
        $got_close and die "write after close";
        $got_data .= $buf;
    } else {
        ++$got_close;
    }
});

ok bzip2(\$test_data, $coderef_write_fh), "bzip2 to write coderef succeeded";
close $coderef_write_fh;
is $got_close, 1, "write fh got close";
is_bzip2ped $got_data, $test_data, "bzip2 to write coderef correct";

