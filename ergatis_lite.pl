#!/usr/local/bin/perl

## Brett Whitty, JCVI, 2007

use lib "/usr/local/devel/ANNOTATION/bwhitty/lib/5.8.8";
use strict;
use warnings;
use Carp;
use Config::IniFiles;
use File::Basename;
use File::Find;
use ErgatisLite::Config;
use ErgatisLite::ErgatisComponentConfig;
use HTML::TreeBuilder;
use HTML::FormatText;

my $o_out = \*STDOUT;
my $e_out = \*STDERR;

## set and check ergatis dirs
my $ergatis_docs = $ErgatisLite::Config::ergatis_root . '/docs';
unless (-d $ergatis_docs) {
    croak "Ergatis docs dir '$ergatis_docs' doesn't seem to exist!";
}
my $ergatis_bin  = $ErgatisLite::Config::ergatis_root . '/bin';
unless (-d $ergatis_bin) {
    croak "Ergatis bin dir '$ergatis_bin' doesn't seem to exist!";
}
my @components = get_ergatis_components();
my $config_ref = get_ergatis_component_config_files();

#use Data::Dumper;
#print Dumper @components;
#print Dumper $config_ref;

print_available_components();

print $o_out tmpl_to_text('/usr/local/devel/ANNOTATION/ard/current/docs/hmmpfam.tmpl');

## my $config_file_name = "$ergatis_docs/$component_name.config";


foreach my $component(@components) {
    print "$component:\n";
    my $config = new ErgatisLite::ErgatisComponentConfig(component => $component);

    #my @flags = $config->getParameters();
    #print join("\n",@flags);

    my %inputs = $config->getDefaults('input');
    my %parameters = $config->getDefaults('parameters');

    my %defaults = (%inputs, %parameters);
    foreach my $key(keys(%defaults)) {
        print $key."\t".$defaults{$key}."\n";
    }
}


## convert the config file into a set of options
sub get_config_options {
    ## comment lines that precede an option should be used as description
    ## for the subsequent option
}

sub print_available_components {

    ## can organize by category using the category information in the ini files
    
    my $component_list = join("\n", @components);
    
    print $o_out "The following components are available:\n";
    print $o_out $component_list."\n";
}

sub get_ergatis_component_config_files {
    
    my %config_files;
    my %xml_files;
    
    find(
         {
             wanted => sub {
                 my $basename = basename($_); 
                 if ($basename =~ /^(.*)\.config$/) { 
                     $config_files{$1} = 1; 
                 } elsif ($basename =~ /^([^\.]+)\.xml/) {
                     $xml_files{$1} = 1;
                 }
                           }, 
             no_chdir => 1
         }, 
         ($ergatis_docs)
        );
        
    foreach my $component(keys(%config_files)) {
        unless ($xml_files{$component}) {
            delete $config_files{$component};
        }
    }
    
    return \%config_files;
    
}

sub get_ergatis_components {

    my $config_hash_ref = get_ergatis_component_config_files();

    return keys(%{$config_hash_ref});
}

sub tmpl_to_text {
    my ($file) = @_;
    
    my $tree = HTML::TreeBuilder->new->parse_file($file);
    my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 80);
    
    return $formatter->format($tree);
}
