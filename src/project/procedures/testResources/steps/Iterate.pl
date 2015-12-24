use strict;
use warnings;
use ElectricCommander;

my $ec = new ElectricCommander({debug => 0});

# Call getResources/getResourcesInPool depending on what the user specified for the pool
my $resources;
my $pool = "$[pool]";
if ($pool eq "") {
    $resources = $ec->getResources();
} else {
    $resources = $ec->getResourcesInPool($pool);
}

# Walk through each resource
foreach my $resource($resources->findnodes("/responses/response/resource")) {
    my $name = $resource->findvalue("resourceName");
    my $alive = $resource->findvalue("agentState/alive")->value();
    if (!$alive) {
        # Don't try the test if the resource isn't alive
        print "Error: $name is not alive, skipping test...\n";
    } else {
        # Try a simple test to ensure the server-agent communication works
        print "$name is alive, running test...\n";
        $ec->createJobStep({
            jobStepName => $name,
            command => 'print "Hello world!";',
            shell => "ec-perl"
        });
    }
}

