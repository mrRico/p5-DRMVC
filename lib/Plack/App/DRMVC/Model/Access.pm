package Plack::App::DRMVC::Model::Access;
use strict;
use warnings;

use base 'Plack::App::DRMVC::Base::Model';
use Config::Mini;
use Net::IP::Match::Trie;
use Net::IP;
use Carp;

sub new {
    my $class = shift;
    my %files = shift;
    my $self = bless {
        has_allow => 0,
        has_deny  => 0
    }, $class;
    
    for my $type (qw(deny allow)) {
        my $file = $files{$type.'_conf'};
        next unless (-f $file and -r _ and -s _);
        
        my $cnf = Config::Mini->new($file);
        $self->{$type.'_file'} = $file;
        my $has_type = 0;
        
        for my $section ($cnf->sections) {
            my @IPv4 = @{$cnf->section($section)->{IPv4}} if $cnf->section($section)->{IPv4};
            push @IPv4, @{$cnf->section($section)->{SUBNETv4}} if $cnf->section($section)->{SUBNETv4};
            if (@IPv4) {
                $has_type ||= 1;
                $self->{$type}->{$section}->{4} = Net::IP::Match::Trie->new();
                $self->{$type}->{$section}->{4}->add(1 => \@IPv4);
            }
            
            my @IPv6 = @{$cnf->section($section)->{IPv6}} if $cnf->section($section)->{IPv6};
            push @IPv6, @{$cnf->section($section)->{SUBNETv6}} if $cnf->section($section)->{SUBNETv6};
            for my $IPv6 (@IPv6) {
                $has_type ||= 1;
                my $checker = Net::IP->new($IPv6, 6);
                croak __PACKAGE__.": Net::IP can't resolv '$IPv6' as IPv6/SUBNETv6" unless $checker;
                push @{$self->{$type}->{$section}->{6}}, $checker;
            }
        }
        
        $self->{'has_'.$type} = $has_type;
    }
    
    return $self;
}

sub is_allow {shift->_check('allow', @_)}
sub is_deny  {shift->_check('deny',  @_)}

sub _check {
    # TODO: general!!!!!!!!!!!!!
    my $self        = shift;
    my $type        = shift;
    my @section     = shift;
    
    return ($type eq 'allow' ? 1 : 0) unless $self->{'has_'.$type}
    
    my $app = Plack::App::DRMVC->instance;
    my $ip = $app->env->{REMOTE_ADDR};
    unless ($ip) {
        $app->log('error', __PACKAGE__.": REMOTE_ADDR is empty");
        return ($type eq 'allow' ? 0 : 1);
    };
    
    my $research_ip = Net::IP->new($ip);
    unless ($research_ip) {
        $app->log('error', __PACKAGE__.": Net::IP don't create object with ip '$ip'");
        return ($type eq 'allow' ? 0 : 1);    
    };
    my $version = $research_ip->version;
    unless ($version) {
        $app->log('error', __PACKAGE__.": Net::IP dont't returns version for ip '$ip'");
        return ($type eq 'allow' ? 0 : 1);    
    };
    
    for my $section (@section) {
        if ($self->{$type}->{$section}) {
            if ($self->{$type}->{$section}->{$version}) {
                # check
                my $res = 0;
                if ($version eq '4') {
                     $res = $self->{$type}->{$section}->{4}->match_ip($ip);
                } elsif ($version eq '6') {
                     my $i = 0;
                     for my $IPv6 (@{$self->{$type}->{$section}->{6}}) {
                        my $overlaps = $IPv6->overlaps($research_ip);
                        if ($overlaps == $IP_B_IN_A_OVERLAP || $overlaps == $IP_IDENTICAL) {
                            $res = 1;
                            if ($i) {
                                # replace IPv6 or SUBNETv6 to first position
                                ($self->{$type}->{$section}->{6}->[0],$self->{$type}->{$section}->{6}->[$i]) =
                                ($self->{$type}->{$section}->{6}->[$i],$self->{$type}->{$section}->{6}->[0])
                            }
                            last;
                        }
                        $i++;
                     }
                } else {
                    $app->log('error', __PACKAGE__.": can't job with ip version '$version' (request ip '$ip')");
                    return ($type eq 'allow' ? 0 : 1);                    
                }
                if ($res) {
                    # если совпадение ip запроса с данными в конфиге было, то
                    # для allow - это allow
                    # для deny - это deny
                    return $type eq 'allow' ? 1 : 1;
                }
            }
        } else {
            $app->log('error', __PACKAGE__.": can't found '$section' in file '".$self->{$type.'_file'}."'");
        }
    }
}


1;
__END__

