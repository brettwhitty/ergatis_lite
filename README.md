# Ergatis Lite

"Ergatis Lite" is an abandoned side-project [Brett Whitty](http://github.com/brettwhitty) started at JCVI in 2007.

The idea was to create a generic command-line tool that would allow the configuring and launching of Ergatis components or pipelines
using an Ergatis/Workflow install without any dependency on the web interface.

### Motivation

In early to mid- 2007 I found myself among the few remaining Bioinformatics Engineers supporting TIGR's core Annotation Group in the newly-merged [TIGR/JCVI](https://en.wikipedia.org/wiki/J._Craig_Venter_Institute), and the lead in-house [Ergatis](http://github.com/brettwhitty/ergatis) developer. Most of the work I was doing at the time was on the [CAMERA](http://www.jcvi.org/cms/research/projects/camera/overview/) project, but I found myself by necessity assuming additional responsibilities supporting a variety of TIGR legacy annotation tools that had been developed and/or supported by other staff who'd recently left the institute.

One of these "legacy" tools was a grid-based parallel blast tool that had a surprisingly high user base; particularly surprising because this was the first time I'd heard of it. There turned out to be a fair amount of user support involved with this, from what I remember, because under certain error situations an admin would need to go in and clean out temporary files, reset queues, etc.

I tried to convince the users that they could get the same (if not more reliable) results from Ergatis by using a nice web interface, but they were used to and/or preferred launching jobs from the command line. (Which I did and do understand completely.)

So this was the inspiration for developing "Ergatis Lite" as a side-project.

### Functionality

The plan was for a user to be able to do:

    ./ergatis_lite.pl --component blastp --input_file /path/to/my_query.fsa --database /path/to/my_subject.db --output_dir /path/to/my_output_dir

...and then wait for the results to appear in the output directory.

I also came up with a simple text templating format that would allow for very easy pipeline template creation to help build various canned pipelines and wrap them in shell scripts as different command line tools; any pipeline variables that were not populated in the template would be required to be provided by the user on the command line at run time.

There were a few features of the templating language that would have added pipeline creation functionality beyond what was possible in the web UI at the time (eg: automatic output => input matching, creating a set of components based on a list of values). Take a look at the comments under '_parseComponent()' in 'ErgatisPipelineTemplate.pm', and the example file 'template_file.txt'.

### Halted Development / Code Status

I ended up misplacing this code when I relocated to MSU in Jan 2008, so development stopped at that time.

I'll need to confirm, but from skimming the code and memory I believe that the code for actually generating a runnable Ergatis/Workflow XML template is pretty far along.

I think most of the work to be done was writing the code that turns the component config variables into command line flags and implementing the various new features supported by the text templating language. Will need to take a closer look and update this README.

#### Author
Brett Whitty, 2017
