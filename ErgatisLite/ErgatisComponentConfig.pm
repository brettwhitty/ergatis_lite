package ErgatisLite::ErgatisComponentConfig;

## Brett Whitty, JCVI, 2007

use ErgatisLite::Config;
use Config::IniFiles;
use Carp;

{

my $cfg;
my $default_config_path = $ErgatisLite::Config::ergatis_root."/docs";

sub new {
    my ($class, %args) = @_;

    my $inifile = undef;
    if ($args{'inifile'}) {
        $inifile = $args{'inifile'};
    } elsif ($args{'component'}) {
        $inifile = $default_config_path."/".$args{'component'}.".config";
    }
   
    unless (-e $inifile) {
        confess "Specified inifile '$inifile' does not exist";
    }
    
    $cfg = new Config::IniFiles( -file => $inifile);
    
    my $self = {
                 
        
               };
    
    return bless $self, $class;
}

sub getParams {
    my ($self, $section, $caps) = @_;
    
    unless ($cfg->SectionExists($section)) {
        die "Section '$section' is not defined in ini file";
    }
    
    my @params = $cfg->Parameters($section);
    unless ($caps) {
        @params = fromCaps(@params);
    }

    return @params;
}

sub getDefaults {
    my ($self, $section) = @_;

    my @keys = $self->getParams($section, 1);

    my %defaults = ();
    foreach my $key(@keys) {
        my $flag = fromCap($key);
        $defaults{$flag} = $cfg->val($section, $key);
    }

    return %defaults;
}

sub getInputs {
    my ($self) = @_;

    my @inputs = self->getParams('input');
    
    return @inputs; 
}

sub getParameters {
    my ($self) = @_;
    
    my @params = $self->getParams('parameters');

    return @params
}

sub getOutputs {
    my ($self) = @_;

    return $cfg->Parameters('output');
}


sub fromCaps {
    my (@arr) = @_;
    
    for ($i = 0; $i < scalar @arr; $i++) {
        $arr[$i] = fromCap($arr[$i]);
    }

    return @arr;
}

sub fromCap {
    my ($val) = @_;
    
    $val =~ s/\$;//g;
    $val = lc($val);

    return $val;
}

sub toCaps {
    my (@arr) = @_;
    
    for ($i = 0; $i < scalar @arr; $i++) {
        $arr[$i] = toCap($arr[$i]);
    }

    return @arr;
}

sub toCap {
    my ($val) = @_;
    
    $val = uc($val);
    $val = '$;'.$val.'$;';

    return $val;
}

}

sub _getParameterSection {
    my ($flag) = @_;

    my $key = toCap($flag);

    my @sections = $cfg->Sections();
    
    foreach $section(@sections) {
        my @parameters = $cfg->Parameters($section);
        foreach my $parameter(@parameters) {
            if ($parameter eq $key) {
                return $section;
            }
        }
    }
    return undef;
}

sub setParameter {
    my ($self, $flag, $value, $section) = @_;

    unless ($section) {
        $section = _getParameterSection($key);
    }
   
    my $parameter = toCap($flag);
   
    if (! defined($section)) {
        confess "Can't find parameter '$parameter' in ini file";
    }
    
    $cfg->setval($section, $parameter, $value);
}

1;
