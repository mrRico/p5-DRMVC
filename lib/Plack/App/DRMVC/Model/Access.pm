package DRMVC::Model::Access;
use strict;
use warnings;

use base 'DRMVC::Base::Model';
use Config::Mini;
use Net::IP::Match::Trie;
use Net::IP;
use Carp;

sub new {
    my $class = shift;
    my %files = @_;
    
    my $self = bless {
    	allow => {
    		has => 0,
    		avaliable_sections => {},
    		file => undef,
    		resolver => {}
    	},
    	deny => {
    		has => 0,
    		avaliable_sections => {},
    		file => undef,
    		resolver => {}
    	},
    	ttl => $files{reload}  
    }, $class;
    
    for my $type (qw(deny allow)) {
        $self->{$type}->{file} = $files{ucfirst $type.'To_conf'};
        next unless ($self->{$type}->{file} and -f $self->{$type}->{file} and -r _ and -s _);
        
        my $cnf = Config::Mini->new($self->{$type}->{file});
        
        my $has_type = 0;
        for my $section ($cnf->sections) {
        	$self->{$type}->{avaliable_sections}->{$section} = 1;
        	
        	# find *v4
            my @IPv4 = @{$cnf->section($section)->{IPv4}} if $cnf->section($section)->{IPv4};
            push @IPv4, @{$cnf->section($section)->{SUBNETv4}} if $cnf->section($section)->{SUBNETv4};
            @IPv4 = grep {$_} @IPv4;
            if (@IPv4) {
                $has_type ||= 1;
                $self->{$type}->{resolver}->{$section}->{4} = Net::IP::Match::Trie->new();
                $self->{$type}->{resolver}->{$section}->{4}->add(1 => \@IPv4);
            }
            
            # find *v6
            my @IPv6 = @{$cnf->section($section)->{IPv6}} if $cnf->section($section)->{IPv6};
            push @IPv6, @{$cnf->section($section)->{SUBNETv6}} if $cnf->section($section)->{SUBNETv6};
            for my $IPv6 (grep {$_} @IPv6) {
                $has_type ||= 1;
                my $checker = Net::IP->new($IPv6, 6);
                croak __PACKAGE__.": Net::IP can't resolv '$IPv6' as IPv6/SUBNETv6" unless $checker;
                push @{$self->{$type}->{resolver}->{$section}->{6}}, $checker;
            }
            
        }        
        $self->{$type}->{has} = $has_type;
    }
    
    return $self;
}

sub is_allow {shift->_check('allow', @_)}
sub is_deny  {shift->_check('deny',  @_)}

sub _check {
    my $self        = shift;
    my $type        = shift;
    my @section     = shift;
    
    # succ
    return ($type eq 'allow' ? 1 : 0) unless $self->{$type}->{has};
    
    my $app = DRMVC->instance;
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
    
    # наличие секций проверено при подключении колбэков для роутера
    for my $section (@section) {
        if ($self->{$type}->{resolver}->{$section}->{$version}) {
            # check
            my $res = 0;
            if ($version eq '4') {
                 $res = $self->{$type}->{resolver}->{$section}->{4}->match_ip($ip);
            } elsif ($version eq '6') {
                 for my $IPv6 (@{$self->{$type}->{resolver}->{$section}->{6}}) {
                    my $overlaps = $IPv6->overlaps($research_ip);
                    if ($overlaps == $IP_B_IN_A_OVERLAP || $overlaps == $IP_IDENTICAL) {
                        $res = 1;
                        last;
                    }
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
    }
    
    return ($type eq 'allow' ? 0 : 0);
}


1;
__END__

