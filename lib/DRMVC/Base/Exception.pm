package DRMVC::Base::Exception;
use strict;
use warnings;

=head1 NAME

DRMVC::Base::Exception

=head1 DESCRIPTION

There is base Exception for you app.

All yours views must have 'process' method.

=head1 DOCUMENTATION

All what you want know about DRMVC you can find here: https://github.com/mrRico/p5-DRMVC/wiki/_pages

=head1 SOURSE

git@github.com:mrRico/p5-DRMVC.git

=head1 SEE ALSO

L<DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

sub new {
    my $class = shift;
    bless {@_}, $class;
}


sub process {die "Not implemented!"}

1;
__END__

