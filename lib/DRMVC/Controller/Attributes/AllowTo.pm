package DRMVC::Controller::Attributes::AllowTo;
use strict;
use warnings;

use base 'DRMVC::Base::AttributeDescription';
use Carp;

my $type = 'allow';

sub init {
    my $class = shift;
    my $value = shift;
    
    my $access = DRMVC->instance->model('DRMVC::Model::Access');
    croak __PACKAGE__.": model DRMVC::Model::Access don't found" unless $access;  
    
    my @setions = $access->{$type}->{resolver}->{general} ? ('general') : ();
    
    for (split(/\s*,\s*/, $value)) {
        next unless $_;
        if ($_ and $access->{$type}->{resolver}->{$_}) {
            push @setions, $_;
        } else {
            croak __PACKAGE__.": can't found section '$_' in file '".$access->{$type}->{file}."'";
        }
    }
    
    return $setions[0] ? [@setions] : undef;
}

sub call_description_coerce {
    my $class   = shift;
    my $desc    = shift;
    my $value   = shift;
    
    $desc->add_match_callback(sub {
        my ($match, $env) = @_;        
        my $access = DRMVC->instance->model('DRMVC::Model::Access');
        unless ($access->is_allow(@$value)) {
            %$match = (
                type  => 'error',
                code  => 403,
                desc  => 'Forbidden'
            );     
            # last callback
            return 0;
        }        
        # to next callback
        return 1;
    });
    
    return 1;
}



1;
__END__
