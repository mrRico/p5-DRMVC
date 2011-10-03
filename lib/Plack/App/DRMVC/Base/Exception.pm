package Plack::App::DRMVC::Base::Exception;

=head1 NAME

Plack::App::DRMVC::Base::Exception

=head1 DESCRIPTION

Base class for all Plack::App::DRMVC's exception.

=head1 METHODS

=cut

=head2 process

Abstract. Handler for exception (must prepare response).

=cut
sub process {die "Not implemented!"}

=head1 SEE ALSO

L<Plack::App::DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

1;
__END__
