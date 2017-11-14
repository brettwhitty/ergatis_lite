package ErgatisLite::ErgatisPipelineTemplate;

## Brett Whitty, JCVI, 2007

use strict;
use warnings;

use ErgatisLite::WorkflowXMLCommandSet;
use ErgatisLite::ErgatisComponent;
use File::Basename;
use XML::Twig;
use Carp;

## my $component_config_source_dir = '';

my $working_dir = '.';
my $source_dir = '.';
## a counter for assigning tokens where not specified
my $token_counters = {};
## global variables defined in template file header directives
my $globals = {};

sub new {
    my ($class, %args) = @_;
    
    my $root = new ErgatisLite::WorkflowXMLCommandSet(type => 'instance');
    my $start = new ErgatisLite::WorkflowXMLCommandSet(type =>'serial', name => 'start');
    
    $root->addChild($start);
    
    my $self = bless {
                    root => $root,
                    start => $start,
                 }, $class;

    return $self;
}

sub parseFile {
    my ($self, $file) = @_;

    open (my $infh, $file) || die "Can't open file '$file': $!";

    my $text = '';
    while (<$infh>) {
        chomp;
        if (/^#\s*(.*)$/) {
            my $global_attribute = $1;
            my ($key, $value) = split("=", $global_attribute, 2);
            if ($key && $value) {
                $globals->{$key} = $value;
            }
        } else {
            $text .= $_;
        }
    }

    ## This should be changed so that whitespace is only removed from the ends of lines
    ## while reading, and parseBrackets should strip any leading or trailing whitespace
    ## as it recursively parses the nested elements
#    $text =~ s/\s+//g;
    
    $self->parseBrackets($text);
}

sub parseBrackets {
    my ($self, $brackets, $parent_element) = @_;

    unless ($parent_element) {
        $parent_element = $self->{'start'};
    }
    
    $brackets =~ s/^\s+(.*)/$1/;
    $brackets =~ s/(.*)\s+$/$1/;
    
    print "brackets = $brackets\n";
    
    unless ($brackets) {
        return;
    }
    if ($brackets =~ /[\,\{\(\<]/) {
        ## '()' encloses a 'serial' command set
        if ($brackets =~ /^\(/) {
            my ($group, $rest) = _bracketStrip($brackets);
            my $element = new ErgatisLite::WorkflowXMLCommandSet(type=>'serial');
            $parent_element->addChild($element);
            $self->parseBrackets($group, $element);
            $self->parseBrackets($rest, $parent_element);
        ## '{}' encloses a 'parallel' command set          
        } elsif ($brackets =~ /^\{/) {
            my ($group, $rest) = _bracketStrip($brackets);
            my $element = new ErgatisLite::WorkflowXMLCommandSet(type=>'parallel');
            $parent_element->addChild($element);
            $self->parseBrackets($group, $element);
            $self->parseBrackets($rest, $parent_element);
        ## '<>' encloses a component definition
        } elsif ($brackets =~ /^\</) {
            my ($component_definition, $rest) = _bracketStrip($brackets);
            ## if ($component_definition =~ /INCLUDE:(.*)/) {
            ##      $group = parseErgatisTemplateFile($1);
            ##      
            ## } else {
            my $component_object = _parseComponent($component_definition);
            my $component_name = $component_object->toString();
            $parent_element->addChild(new ErgatisLite::WorkflowXMLCommandSet(type=>'serial', name=>$component_name));
            ## }
            $self->parseBrackets($rest, $parent_element);
        ## not sure, but appears that naked string is handled as a component name
        } elsif ($brackets =~ /^([^,]+)[,]?(.*)/) {
            my $element = new ErgatisLite::WorkflowXMLCommandSet(type=>'serial', name=>$1);
            $parent_element->addChild($element);
            $self->parseBrackets($2, $parent_element);
        }    
    } else {
        ## no brackets, so again seems to be handled as component name
        $parent_element->addChild(new ErgatisLite::WorkflowXMLCommandSet(type=>'serial', name=>$brackets));
    }
}

sub _bracketStrip {
    my ($string) = @_;
    
   my $chars = {
                    '(' => ')',
                    '[' => ']',
                    '{' => '}',
                    '<' => '>',
               };
   my $stacks = {
                    '(' => [],
                    '[' => [],
                    '{' => [],
                    '<' => [],
                };
                
   my $bracket_char = substr($string, 0, 1);
   push(@{$stacks->{$bracket_char}}, 0);

   $string = substr($string, 1);   
   my $string_length = length($string);
   
   my $start = 0;
   my $stop = 0;
  
   my $exit_flag = 0;
   for (my $i = 0; $i < $string_length; $i++) {
     my $char = substr($string, $i, 1);
     if ($char eq $bracket_char) {
         push(@{$stacks->{$bracket_char}}, $i);
     } elsif ($char eq $chars->{$bracket_char}) {
         $start = pop @{$stacks->{$bracket_char}};
         $stop = $i;
         unless (scalar @{$stacks->{$bracket_char}}) {
             $exit_flag = 1;
             last;
         }
     } 
   }
   unless ($exit_flag) {
    confess "ERROR: unclosed bracket";
   }
   my $left_side = substr($string, $start, $stop - $start);
   my $right_side = substr($string, $stop + 1);

   ## strip leading comma
   $right_side =~ s/^,//;

   return ($left_side, $right_side); 
}

sub _parseComponent {
    my ($component_def) = @_;

    ## component definition string can take the following form:
    ##
    ## component_name.token:key=value;key2=value2;
    # both token and key/value pairs are not required
    ## also
    ## /absolute/path/to/component_name.token.config:key=value;key2=value2;
    # if an absolute path to a config file is provided, it will be used as the starting default values
    ## also
    ## component_name.token:key=value;&key=/path/to/list_file_of_values.txt;
    # the & before a key creates a set or series of components for all values of the key in the list file
    ## also
    ## component_name.token:input_file_list=[other_component.token];
    # the [] brackets will invoke the output -> input matching appropriate for the input type of the key
    # which may be defined in some document that links input/output keys for components
    ## also
    ## component_name.token:*IN=[other_component.token];
    # the special key *IN will invoke the automatic output -> input matching function
    ## also
    ## component_name.token:key1=value1;KEY2=global_variable;
    # uppercase KEY2 indicates the value specified to the key is a global variable
    ##
    ## values in key/value pairs should have URL encoding for the following characters:
    ## ;=\s
    ##
    ## Also want to be able to include another XML template file via include like so:
    ##
    ## <INCLUDE:/path/to/xml/template_file.some_extension>
    ##
    ## I like the INCLUDE directive above. Will be handled by doing a $self->parseErgatisPipelineTemplate($file)
    ## then replacing 
    ##
    ## Also, remote files can be included using the following syntax:
    ##
    ## key=@URL://to/remote/file.in
    ##
    ## file will be retrieved and stored to a pipeline working directory
    ## and will support archived files such as .zip, .tar.gz, .tgz, .gz, .bz2
    ##
    my ($component_name, $attribute_string) = split(":", $component_def, 2);

    my @attribute_kv_strings = ();
    if ($attribute_string) {
        @attribute_kv_strings = split(";", $attribute_string);
    }

    my %attributes = ();
    foreach my $attribute_kv_string(@attribute_kv_strings) {
        if ($attribute_kv_string) {
            my ($key, $value) = split("=", $attribute_kv_string, 2);
            $attributes{$key} = $value;
        }
    }
    
    my $component_filename = undef;
    if ($component_name =~ /\.config$/) {
        $component_filename = $component_name; 
        $component_name = basename($component_filename, ".config");
    }
   
#    print STDERR $component_name."\n";
    
    my ($component, $token) = split(/\./, $component_name, 2);

#    print STDERR $component_filename."\n";
    
    unless ($token) {
        $token = _getToken($component);
    }
  
    ## Instead of creating component config objects here, we should be creating
    ## ErgatisLite::ErgatisComponent objects which may or may not have instantiated
    ## component configs, but can still store the attributes assigned to them
    ## and will be assigned unique identifiers (like S1C1 -- serial group 1, component 1)
    ## so that they can be specifically referenced when the pipeline template object is
    ## fully populated
    
    my $component_object = new ErgatisLite::ErgatisComponent(
                                                name => $component, 
                                                token => $token, 
                                                source => $component_filename,
                                                attributes => \%attributes
                                                            );
    
    
    return $component_object;
}

sub _getToken {
    my ($component) = @_;
    
    $token_counters->{$component}++;
    
    return "default_".$token_counters->{$component};
}

sub parseErgatisPipelineTemplate {
        my ($self, $file) = @_;    
   
        my $ifh; 
        if ($file =~ /\.(gz|gzip)$/) {
            open ($ifh, "<:gzip", $file);
        } else {
            open ($ifh, "<$file");
        }
        
        my $twig = new XML::Twig(   TwigRoots => {'commandSetRoot' => 1},
                                    TwigHandlers => {'commandSetRoot' => \&_parseCommandSetRoot}
                                );
        
        $twig->parse($ifh);
        close $ifh;
 
}
sub _parseCommandSetRoot {
    my ($twig, $child) = @_;

    my $result = _parseCommandSet($child->first_child());
    print $result;
}

sub _parseCommandSet {
    my ($commandset, $result) = @_;

    my %open_chars = (
                    'parallel' => '{',
                    'serial'   => '(',
                     );
    my %close_chars = (
                    'parallel' => '}',
                    'serial'   => ')',
                      );
    
    my $type = ($commandset->{'att'}->{'type'}) ? $commandset->{'att'}->{'type'} : undef;
    
    if ($type && $type eq 'serial' && $commandset->first_child('name')) {
        my $name = $commandset->first_child('name')->text;
        if ($name ne 'start') {
            $result .= $name;
            return $result;
        }
    }
                      
    my @children = $commandset->children('commandSet');
    if ($type) {
        $result .= $open_chars{$type};
    }
    
    for (my $i=0; $i < scalar(@children); $i++) {
        $result = _parseCommandSet($children[$i], $result);
        if ($i < scalar(@children) - 1) {
            $result .= ",";
        }
    }
    if ($type) {
        $result .= $close_chars{$type};
    }
    return $result;
}

1;
