#!/usr/bin/env perl

# Build, upload and promote EC-Admin using ecpluginbuilder
#		https://github.com/electric-cloud/ecpluginbuilder

use Getopt::Long;
use Data::Dumper;
use strict;
use File::Copy;

use ElectricCommander ();
$| = 1;
my $ec = new ElectricCommander->new();

my $epb="../ecpluginbuilder";

my $pluginVersion = "3.1.8";
my $pluginKey = "EC-Admin";

GetOptions ("version=s" => \$pluginVersion)
		or die (qq(
Error in command line arguments

	createPlugin.pl
		[--version <version>]
		)
);

# Read buildCounter
my $buildCounter;
{
  local $/ = undef;
  open FILE, "buildCounter" or die "Couldn't open file: $!";
  $buildCounter = <FILE>;
  close FILE;

 $buildCounter++;
 $pluginVersion .= ".$buildCounter";
 print "[INFO] - Incrementing build number to $buildCounter...\n";

 open FILE, "> buildCounter" or die "Couldn't open file: $!";
 print FILE $buildCounter;
 close FILE;
}
my $pluginName = "${pluginKey}-${pluginVersion}";



print "[INFO] - Creating plugin '$pluginName'\n";

system ("$epb -pack-jar -plugin-name $pluginKey -plugin-version $pluginVersion " .
 " -folder META-INF" .
 " -folder dsl" .
 " -folder htdocs" .
 " -folder lib" .
 " -folder lib5" .
 " -folder pages");

move("build/${pluginKey}.jar", ".");

# Uninstall old plugin
#print "[INFO] - Uninstalling old plugin...\n";
#$ec->uninstallPlugin($pluginKey) || print "No old plugin\n";

# Install plugin
print "[INFO] - Installing plugin ${pluginKey}.jar...\n";
system ('date');
$ec->installPlugin("${pluginKey}.jar");
system ('date');

# Promote plugin
print "[INFO] - Promoting plugin...\n";
system ('date');
$ec->promotePlugin($pluginName);
system ('date');