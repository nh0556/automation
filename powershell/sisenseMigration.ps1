##############################################################################
# Function definitions
##############################################################################

. .\commonUtils.ps1

# Script starts here

$migrationDirRoot = "c:\temp\sisenseMigration\run_{0}" -f (get-date).ToString("yyyy-MM-dd-hh-mm-ss")

$actualProgramFiles = (Get-ChildItem Env:ProgramFiles).value
$actualPFSisenseRoot = "$actualProgramFiles\Sisense"

$actualSisenseProgramData = "c:\ProgramData\Sisense"

$sisenseMigrationTasks=@(
    @{
        action="manage-service";
        serviceName="iisadmin";
        serviceAction="stop"
    },
    @{
        action="manage-service";
        serviceName="WAS";
        serviceAction="stop";
        skip=$true
    },
    @{
        action="manage-service";
        serviceName="W3SVC";
        serviceAction="stop"
    },
    @{
        action="manage-service";
        serviceName="Sisense.Repository";
        serviceAction="stop"
    },
    @{
        action="copy-file";
        src="$actualPFSisenseRoot\PrismWeb\vnext\config\default.yaml";
        dest="$migrationDirRoot\Program Files\Sisense\PrismWeb\vnext\config";
        create_dest_dir=$true
    },
    @{
        action="copy-file";
        src="$actualPFSisenseRoot\PrismWeb\App_Data\Configurations\db.config";
        dest="$migrationDirRoot\Program Files\Sisense\PrismWeb\App_Data\Configurations";
        create_dest_dir=$true
    },
    @{
        action="copy-file";
        src="$actualPFSisenseRoot\Infra\MongoDB\mongodbconfig.conf";
        dest="$migrationDirRoot\Program Files\Sisense\Infra\MongoDB";
        create_dest_dir=$true
    },
    # copy SSO configuration
    @{
        action="copy-file";
        src="$actualPFSisenseRoot\PrismWeb\LoginSisense.ashx";
        dest="$migrationDirRoot\Program Files\Sisense\PrismWeb\";
        create_dest_dir=$true
    },
    # Stop ElastiCubes
    @{
        action="stop-elastiCube";
        cubeName="Sample ECommerce"
    },
    @{
        action="stop-elastiCube";
        cubeName="Sample Healthcare"
    },
    @{
        action="stop-elastiCube";
        cubeName="Sample Lead Generation"
    }
    # backup elasticCubes and archive to migration dir
    @{
        action="copy-dir-recursively";
        src="$actualSisenseProgramData\PrismServer\ElastiCubeData";
        dest="$migrationDirRoot\ProgramData\Sisense\PrismServer\ElasticCubeData";
        create_dest_dir=$true;
        archive=$true;
        # skip=$true
    },
    # backup Sisense Plugins
    @{
        action="copy-dir-recursively";
        src="$actualPFSisenseRoot\PrismWeb\plugins";
        dest="$migrationDirRoot\Program Files\Sisense\PrismWeb\";
        create_dest_dir=$true;
        # skip=$true
    },
    # start ElastiCubes
    @{
        action="start-elastiCube";
        cubeName="Sample ECommerce"
    },
    @{
        action="start-elastiCube";
        cubeName="Sample Healthcare"
    },
    @{
        action="start-elastiCube";
        cubeName="Sample Lead Generation"
    },
    @{
        action="manage-service";
        serviceName="Sisense.Repository";
        serviceAction="start"
    },
    @{
        action="manage-service";
        serviceName="iisadmin";
        serviceAction="start"
    },
    @{
        action="manage-service";
        serviceName="WAS";
        serviceAction="start"
    },
    @{
        action="manage-service";
        serviceName="W3SVC";
        serviceAction="start"
    }
)

foreach($task in $sisenseMigrationTasks) {
    if (-not ($task.contains('skip'))) {
        handleTask -task $task
    } else {
        write-host "!!! skipping " + $task.action
    }
}

Tree $migrationDirRoot /A /F