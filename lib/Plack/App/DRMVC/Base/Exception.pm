package Bicycle::Base::Exception;

=head1 NAME

Bicycle::Base::Exception

=head1 DESCRIPTION

Base class for all Bicycle's exception.

=head1 METHODS

=cut

=head2 process

Abstract. Handler for exception (must prepare response).

=cut
sub process {die "Not implemented!"}

=head1 SEE ALSO

L<Bicycle>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
