package Velicio::Constants;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(STATEDIR REGISTRATION);
@EXPORT_OK = qw(myfunc);

use constant STATEDIR => 'state';
use constant REGISTRATION => STATEDIR.'/registration';

sub myfunc {}

1;
