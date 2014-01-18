package Velicio::Util;

use Mojo::Base 'Exporter';

our @EXPORT_OK = (
  qw(uuid),
);

sub uuid {
  join "-", map { unpack "H*", $_ } map { substr pack("I", (((int(rand(65536)) % 65536) << 16) | (int(rand(65536)) % 65536))), 0, $_, "" } ( 4, 2, 2, 2, 6 )
}

1;
