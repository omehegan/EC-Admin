$[/myProject/scripts/perlHeader]

#############################################################################
#
# Parameters
#
#############################################################################
my $pCategory="$[Category]";
my $project="$[Project]";
my $projectAsCode="$[projectAsCode]";

my $pName="$[/myJob/pluginName]";

my $ECsetup="";

#
# Add the projectAsCode bit if selected
#
if ($projectAsCode eq "true") {

  $ECsetup .= << 'ENDOFPAC';
if ($promoteAction eq 'promote') {
<<<<<<< HEAD
    my $pluginName = '@'.'PLUGIN_NAME@';
    my $pluginKey = '@'.'PLUGIN_KEY@';
=======
    my $pluginName = '@PLUGIN_NAME@';
    my $pluginKey = '@PLUGIN_KEY@';
>>>>>>> 59a3a1c60a3ba4d245eaa4461d05e3e5da5c7c0f

    # The purpose of a "ProjectAsCode" plugin is to develop a PROJECT so it can be checked
    # into source control and properly revisioned.  End users of these projects shouldn't
    # be aware of plugins usage on the back-end.  So we create a project by the same name
    # as the plugin key (without a version number) and update that project in-place when a
    # different version is promoted.  To achieve this, we use export and import instead of
    # delete and clone so we can preserve jobs/workflows which would otherwise be lost.

    # Use the logs directory for the temporary export file (we know it's writable by the
    # server since it writes its logs there).
    my $exportFile = $commander->getProperty("/server/Electric Cloud/dataDirectory")
        ->findvalue("//value")->value() . "/logs/$pluginName.xml";
    $commander->export($exportFile, {path => "/projects/$pluginName"});
    $commander->import($exportFile, {path => "/projects/$pluginKey", force => 1});
    unlink($exportFile);

    # Delete the ec_setup & ec_visibility properties from the user-facing project since they're irrelevant.
    $commander->deleteProperty("/projects/$pluginKey/ec_setup");
<<<<<<< HEAD
    $commander->deleteProperty("/projects/$pluginKey/ec_visibility");}
=======
    $commander->deleteProperty("/projects/$pluginKey/ec_visibility");
}
>>>>>>> 59a3a1c60a3ba4d245eaa4461d05e3e5da5c7c0f
ENDOFPAC

}	# end of projectAsCode block

#
# Pickup code for Promote/demote
#
if (getP("/projects/$project/promoteAction")) {
  $ECsetup .= "# promote/demote action\n";
  $ECsetup .= getP("/projects/$project/promoteAction");
  $ECsetup .= "\n\n";
}

$ECsetup .= "# Data that drives the create step picker registration for this plugin.\n";

# Loop on each procedure
my $proc;              # Loop variable
my $xpath;
my $pickerList="";

my @procList=$ec->getProcedures($project)->findnodes("//procedure");
foreach $xpath(@procList) {
   my $procName=$xpath->findvalue("//procedureName");
   
   #
   # Skip this procedure if property "exposeToPlugin" is not set to 1
   #
   next if (getP("/projects/$project/procedures/$procName/exposeToPlugin") != 1);
   
   #
   #
   # If property "descrirptionForPlugin" exists, use it
   # if not, use the procedure description itself
   #
   my $description=getP("/projects/$project/procedures/$procName/descriptionForPlugin");
   if (!$description) {
     $description=$xpath->findvalue("//description");
   }
   my $procCleanName=$procName;
   $procCleanName =~ s/[\s\-\.]/\_/g; # replace spaces, . and - by _

# Create a block of perl Code for each procedure ala
#my %startBuild = (
#    label => "$Jenkins- Start a build",
#    procedure => "startBuild",
#    description => "Start a build.",
#    category => "Other"
#);

#escape double quote in the description
  $description =~ s/"/\\"/g;
  
   $ECsetup .= "my %" . "$procCleanName = ( 
  label       => \"$pName - $procName\", 
  procedure   => \"$procName\", 
  description => \"$description\", 
  category    => \"$pCategory\" 
);

" ;

  $pickerList .= "\\%". $procCleanName . ", "; 
} # end foreach loop


# Create the picker List ala
#@::createStepPickerSteps = (\%startBuild, \%getStatus, \%getLog, \%getDuration);

#remote the trailing ", " from the picker List
chop($pickerList); chop($pickerList);
$ECsetup .= "\@::createStepPickerSteps = (" . $pickerList . ");\n";

print "Code generated\n";
print $ECsetup;

my $ec_setupFile = "project/ec_setup.pl";
open (SETUP, ">$ec_setupFile") or die "$ec_setupFile:  $!\n";
print SETUP $ECsetup, "\n";
close SETUP;

$[/myProject/scripts/perlLib]


