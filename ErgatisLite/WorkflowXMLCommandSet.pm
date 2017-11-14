package ErgatisLite::WorkflowXMLCommandSet;

## Brett Whitty, JCVI, 2007

use strict;
use warnings;

my $name;
my $type;
my $id;

{

sub new {
    my ($class, %args) = @_;

    $type = ($args{'type'}) ? $args{'type'} : '';
    $name = ($args{'name'}) ? $args{'name'} : '';
    $id = ($args{'id'}) ? $args{'id'} : undef;
    
    my $self = bless {
                        _children => [],
                        type => $type,
                        name => $name,
                        id => $id,
                     }, $class;

    return $self;
}

}
sub toString {
    my ($self, $indent) = @_;
    
    my $head;
    my $tail;
    
    
    if ($self->{'type'} eq 'instance') {
    
    ## $head is the head of the pipeline xml document
    $head = <<HEAD;
<commandSetRoot xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schema Location="commandSet.xsd" type="instance">
HEAD

    ## $tail is the tail of the pipeline xml document
    $tail = <<TAIL;
</commandSetRoot>
TAIL
    } else {
    
    $indent .= " " x 4;
    
    ## $head is the head of the pipeline xml document
    $head = <<HEAD;
$indent<commandSet type="$self->{type}">
$indent    <state>incomplete</state>
HEAD
if ($self->{'name'}) {
    $head .= "$indent    <name>$self->{name}</name>\n";
}

    ## $tail is the tail of the pipeline xml document

    $tail = <<TAIL;
$indent</commandSet>
TAIL
    }
    
    my $text = '';
    my $children = $self->getChildren();
    foreach my $child(@{$children}) {
        $text .= $child->toString($indent);
    }
    $text = $head . $text . $tail;
   
    return $text;
    
}
sub getChildren {
    my ($self) = @_;

    return $self->{'_children'};
}

sub addChild {
    my ($self, $child) = @_;

    push (@{$self->{'_children'}}, $child);
}

1;
