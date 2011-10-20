package DRMVC::Base::Model;
use strict;
use warnings;

=head1 NAME

DRMVC::Base::Model

=head1 DESCRIPTION

There is base Model for you app.

If 'new' method is defined, all others methods could be invoked as objects methods, otherwise as 'class' methods.

=head1 SYNOPSIS

    my $app = MyApp->instance;
    
    # get class name or instance from MyApp::Model::Some::Data 
    $app->model('Some::Data');
    # or
    $app->model('MyApp::Model::Some::Data');
    
=head1 DOCUMENTATION

All what you want know about DRMVC you can find here: https://github.com/mrRico/p5-DRMVC/wiki/_pages

=head1 SOURSE

git@github.com:mrRico/p5-DRMVC.git

=head1 SEE ALSO

L<DRMVC>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut

my $cache__short_name = {};
my $ns;

sub __short_name {
    my $class = shift;
    return $cache__short_name->{$class} if $cache__short_name->{$class};     
    
    $ns ||= join ('|', map {(ref $_ || $_).'::'} 'DRMVC::Model', @{DRMVC->instance->ini_conf->section('mvc')->{'model.namespace'}});
    ($cache__short_name->{$class} = $class) =~ s/^(DRMVC::Model::|$ns)//;
    
    return $cache__short_name->{$class};
}

1;
__END__
