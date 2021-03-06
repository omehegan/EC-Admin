#############################################################################
#
#  Save projects, procedures and workflows (DSL or XML)
#
#  Author: L.Rochette
#
#  Copyright 2013-2018 Electric-Cloud Inc.
#
#     Licensed under the Apache License, Version 2.0 (the "License");
#     you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#     Unless required by applicable law or agreed to in writing, software
#     distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#     limitations under the License.
#
# History
# ---------------------------------------------------------------------------
# 2019-Feb-11 lrochette Foundation for merge DSL and XML export
# 2019-Feb 21 lrochette Changing paths to match EC-DslDeploy
# 2019-Feb-25 lrochette Save schedules
#############################################################################
use File::Path;

$[/myProject/scripts/perlHeaderJSON]

#
# Parameters
#
my $path             = '$[pathname]';
my $exportSteps      = "$[exportSteps]";
my $pattern          = '$[pattern]';
my $caseSensitive    = "i";
my $includeACLs      = "$[includeACLs]";
my $includeNotifiers = "$[includeNotifiers]";
my $relocatable      = "$[relocatable]";
my $format           = '$[format]';

#
# Global
#
my $errorCount = 0;
my $projCount  = 0;
my $procCount  = 0;
my $stepCount  = 0;
my $wkfCount   = 0;
my $schedCount = 0;

# Set the timeout to config value or 600 if not set
my $defaultTimeout = getP("/server/EC-Admin/cleanup/config/timeout");
$ec->setTimeout($defaultTimeout? $defaultTimeout : 600);

# Get list of Project
my ($success, $xPath) = InvokeCommander("SuppressLog", "getProjects");

# Create the Projects directory
mkpath("$path/projects");
chmod(0777, "$path/projects") or die("Can't change permissions on $path/projects: $!");

foreach my $node ($xPath->findnodes('//project')) {
  my $pName=$node->{'projectName'};
  my $pluginName=$node->{'pluginName',};

  # skip plugins
  next if ($pluginName ne "");

  # skip projects that don't fit the pattern
  next if ($pName !~ /$pattern/$[caseSensitive] );  # / just for the color

  printf("Saving Project: %s\n", $pName);

  my $fileProjectName=safeFilename($pName);
  mkpath("$path/projects/$fileProjectName");
  chmod(0777, "$path/projects/$fileProjectName");

  my ($success, $res, $errMsg, $errCode) =
    backupObject($format, "$path/projects/$fileProjectName/project",
  		"/projects[$pName]", $relocatable, $includeACLs, $includeNotifiers);
  if (! $success) {
    printf("  Error exporting project %s", $pName);
    printf("  %s: %s\n", $errCode, $errMsg);
    $errorCount++;
  } else {
    $projCount++;
  }

  #
  # Save schedules
  #
  mkpath("$path/projects/$fileProjectName/schedules");
  chmod(0777, "$path/projects/$fileProjectName/schedules");

  my ($success, $xPath) = InvokeCommander("SuppressLog", "getSchedules", $pName);
  foreach my $proc ($xPath->findnodes('//schedule')) {
    my $schedName=$proc->{'scheduleName'};
    my $fileScheduleName=safeFilename($schedName);
    printf("  Saving schedule: %s\n", $schedName);

    mkpath("$path/projects/$fileProjectName/schedules/$fileScheduleName");
    chmod(0777, "$path/projects/$fileProjectName/schedules/$fileScheduleName");
 	  my ($success, $res, $errMsg, $errCode) =
      backupObject($format, "$path/projects/$fileProjectName/schedules/$fileScheduleName/schedule",
  			"/projects[$pName]schedules[$schedName]", $relocatable, $includeACLs, $includeNotifiers);

    if (! $success) {
      printf("  Error exporting schedule %s", $schedName);
      printf("  %s: %s\n", $errCode, $errMsg);
      $errorCount++;
    }
    else {
      $schedCount++;
    }
  }     #schedule loop

  #
  # Save procedures
  #
  mkpath("$path/projects/$fileProjectName/procedures");
  chmod(0777, "$path/projects/$fileProjectName/procedures");

  my ($success, $xPath) = InvokeCommander("SuppressLog", "getProcedures", $pName);
  foreach my $proc ($xPath->findnodes('//procedure')) {
    my $procName=$proc->{'procedureName'};
    my $fileProcedureName=safeFilename($procName);
    printf("  Saving Procedure: %s\n", $procName);

    mkpath("$path/projects/$fileProjectName/procedures/$fileProcedureName");
    chmod(0777, "$path/projects/$fileProjectName/procedures/$fileProcedureName");
 	  my ($success, $res, $errMsg, $errCode) =
      backupObject($format, "$path/projects/$fileProjectName/procedures/$fileProcedureName/procedure",
  			"/projects[$pName]procedures[$procName]", $relocatable, $includeACLs, $includeNotifiers);

    if (! $success) {
      printf("  Error exporting procedure %s", $procName);
      printf("  %s: %s\n", $errCode, $errMsg);
      $errorCount++;
    }
    else {
      $procCount++;
    }
    #
    # Save steps
    #
    if ($exportSteps) {
      mkpath("$path/projects/$fileProjectName/procedures/$fileProcedureName/steps");
      chmod(0777, "$path/projects/$fileProjectName/procedures/$fileProcedureName/steps");

      my($success, $stepNodes) = InvokeCommander("SuppressLog", "getSteps", $pName, $procName);
      foreach my $step ($stepNodes->findnodes('//step')) {
        my $stepName=$step->{'stepName'};
        my $fileStepName=safeFilename($stepName);
        printf("    Saving Step: %s\n", $stepName);

 	      my ($success, $res, $errMsg, $errCode) =
          backupObject($format,
            "$path/projects/$fileProjectName/procedures/$fileProcedureName/steps/$fileStepName",
  					"/projects[$pName]procedures[$procName]steps[$stepName]", $relocatable,
            $includeACLs, $includeNotifiers);

        if (! $success) {
          printf("  Error exporting step %s", $stepName);
          printf("  %s: %s\n", $errCode, $errMsg);
          $errorCount++;
        } else {
          $stepCount++;
        }

      }  # step loop

    } # fi stepExport
  }   # procedure loop

  #
  # Save workflow definitions
  #
  mkpath("$path/projects/$fileProjectName/Workflows");
  chmod(0777, "$path/projects/$fileProjectName/Workflows");

  my ($success, $xPath) = InvokeCommander("SuppressLog", "getWorkflowDefinitions", $pName);
  foreach my $proc ($xPath->findnodes('//workflowDefinition')) {
    my $wkfName=$proc->{'workflowDefinitionName'};
    my $fileWkfName=safeFilename($wkfName);
    printf("  Saving Workflow Definition: %s\n", $wkfName);

    my ($success, $res, $errMsg, $errCode) =
      backupObject($format, "$path/projects/$fileProjectName/Workflows/$fileWkfName",
  			"/projects[$pName]workflowDefinitions[$wkfName]", $relocatable, $includeACLs, $includeNotifiers);

    if (! $success) {
      printf("  Error exporting %s", $wkfName);
      printf("  %s: %s\n", $errCode, $errMsg);
      $errorCount++;
    }
    else {
      $wkfCount++;
    }
  }

}
my $str="";
$str .= createExportString($projCount,  "project");
$str .= createExportString($procCount,  "procedure");
$str .= createExportString($wkfCount,   "workflow");
$str .= createExportString($schedCount, "schedule");

$ec->setProperty("preSummary", $str);

$ec->setProperty("/myJob/projectExported", $projCount);
$ec->setProperty("/myJob/procedureExported", $procCount);
$ec->setProperty("/myJob/workflowExported", $wkfCount);
$ec->setProperty("/myJob/scheduleExported", $schedCount);

exit($errorCount);

$[/myProject/scripts/perlBackupLib]
$[/myProject/scripts/perlLibJSON]
