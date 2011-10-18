package DRMVC::Base::Exception;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

=head1 NAME

DRMVC::Base::Exception

=head1 DESCRIPTION

Base class for all DRMVC's exception.

=head1 METHODS

=cut

=head2 process

Abstract. Handler for exception (must prepare response).

=cut
sub process {die "Not implemented!"}

=head1 SEE ALSO

L<DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__

