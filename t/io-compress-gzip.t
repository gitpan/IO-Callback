# IO::Callback 1.04 t/io-compress-gzip.t
# Check that IO::Callback inter-operates with IO::Compress::Gzip

use strict;
use warnings;

use Test::More;
BEGIN {
    eval 'use IO::Compress::Gzip qw/gzip/';
    plan skip_all => 'IO::Compress::Gzip required' if $@;

    eval 'use IO::Uncompress::Gunzip qw/gunzip/';
    plan skip_all => 'IO::Uncompress::Gunzip required' if $@;

    plan tests => 4;
}
use Test::NoWarnings;

use Fatal qw/close/;
use IO::Callback;

my $test_data = "foo\n" x 100;

my $lines = 0;
my $coderef_read_fh = IO::Callback->new('<', sub {
    return if $lines++ >= 100;
    return "foo\n";
});

my $compressed;
gzip($coderef_read_fh, \$compressed) or die "gzip failed";
is_gzipped( $compressed, $test_data, "gzip from read coderef correct" );


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

gzip(\$test_data, $coderef_write_fh) or die "gzip failed";
close $coderef_write_fh;
is( $got_close, 1, "write fh got close" );
is_gzipped( $got_data, $test_data, "gzip to write coderef correct" );


sub is_gzipped {
    my ($gzgot, $want, $comment) = @_;

    my $got;
    gunzip(\$gzgot, \$got) or die "gunzip failed";
    is( $got, $want, $comment );
}

    

