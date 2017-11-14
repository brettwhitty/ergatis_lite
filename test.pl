#!/usr/local/bin/perl

## Brett Whitty, JCVI, 2007

use strict;
use warnings;
use ErgatisLite::ErgatisPipelineTemplate;

my $pipe = new ErgatisLite::ErgatisPipelineTemplate; 

use Data::Dumper;
print Dumper $pipe;

$pipe->parseFile("template_file.txt"); 
print $pipe->{'root'}->toString();
$pipe->parseErgatisPipelineTemplate("/usr/local/annotation/PANGENOME/workflow/project_saved_templates/pangenome/pipeline.layout");
