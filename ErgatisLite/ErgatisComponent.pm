package ErgatisLite::ErgatisComponent;

## Brett Whitty, JCVI, 2007

use ErgatisLite::ErgatisComponentConfig;

sub new {
    my ($class, %args) = @_;

    my $name = ($args{'name'}) ? $args{'name'} : undef;
    my $token = ($args{'token'}) ? $args{'token'} : undef;
    my $id = ($args{'id'}) ? $args{'id'} : undef;
    my $source = ($args{'source'}) ? $args{'source'} : undef;
    my $attributes = ($args{'attributes'}) ? $args{'attributes'} : undef;
    
    return bless {
                    id      => $id,
                    name    => $name,
                    token   => $token,
                    source  => $source,
                    attributes  => $attributes,
                 }, $class;
}

my $_is_abstract = 1;
    
sub isAbstract {
    return $_is_abstract;
}

sub _setAttributes {
    my (%attributes) = @_;
    
    foreach my $key(keys(%attributes)) {
      
        ## had to disable until I figure out how I want to handle making the path
        ## to where the config files live available to ErgatisComponentConfig  
        #$component_config->setParameter($key, $attributes{$key});
    }

}

sub toString {
    my ($self) = @_;

    return $self->{'name'}.".".$self->{'token'};
}

1;
