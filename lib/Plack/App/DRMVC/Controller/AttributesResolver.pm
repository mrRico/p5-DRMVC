package Plack::App::DRMVC::Controller::AttributesResolver;
use strict;
use warnings;

use Module::Pluggable;
use Module::Load;

my $self = undef;

sub new {
    return $self if $self;
     
    my $class = shift;
    my $bi = Plack::App::DRMVC->instance;
    $self = bless {controller_attributes => {}}, $class;
    
    # custom controller_attributes description override default
    for my $att_desc_class ('Plack::App::DRMVC::Controller::Attributes', $self->ini_conf->{_}->{app_name}.'::Extend::Controller::Attributes') {
        Module::Pluggable->import(search_path => [$att_desc_class], sub_name => '_plu');
        for (__PACKAGE__->_plu) {
            load $_;
            next unless $_->isa('Plack::App::DRMVC::Base::AttributeDescription');
            my $ns = $att_desc_class.'::';
            (my $shot_name = $_) =~ s/^$ns//;
            $self->{controller_attributes}->{$shot_name} = $_;
        };
    }
    
    return $self;    
}

# получает исходное название аттрибута и значение, отправляет на фабрику
sub init {
    my $self = shift;
    my %param = @_;
        
    return exists $self->{controller_attributes}->{$param{name}} ? $self->{controller_attributes}->{$param{name}}->init($param{value}) : undef; 
}

# полчив все данные (описание запроса) пробегает все классы аттрибутов. чтобы уточнить запрос
sub call_description_coerce {
    my $self    = shift;
    my $subinfo = shift;
    my $desc    = shift;
    
    for my $attr_short_name (keys %$subinfo) {
        $self->{controller_attributes}->{$attr_short_name}->call_description_coerce($desc, $subinfo->{$attr_short_name});
    }
    
    return;
}


1;
__END__
