#!/usr/bin/perl -w
use Cwd;

my $text = "path/to/newproject/";

@path = split("/", $text);

my $last = pop @path;

my $path2expFolder = join("/",@path);
$path2expFolder = "/$path2expFolder";
my $cwd			= cwd;




print "\n\n $last \n\n $path2expFolder \n\n $cwd \n\n";




exit 0;
