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
    # copy GraphQL conf file
    @{
        action="copy-file";
        src="$actualPFSisenseRoot\PrismWeb\ECMNext\GraphQL\src\config\default.yaml";
        dest="$migrationDirRoot\Program Files\Sisense\PrismWeb\ECMNext\GraphQL\src\config";
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
        cubeName="Sample ECommerce";
        skip=$true
    },
    @{
        action="stop-elastiCube";
        cubeName="Sample Healthcare";
        skip=$true
    },
    @{
        action="stop-elastiCube";
        cubeName="Sample Lead Generation";
        skip=$true
    },
    @{
        action="stop-elastiCube";
        cubeName="DEV - Analytics"
    },
    @{
        action="stop-elastiCube";
        cubeName="Dev - Legacy Reports"
    },
    @{
        action="stop-elastiCube";
        cubeName="DEV - Pathfinder - BI"
    },
    # backup elasticCubes and archive to migration dir
    @{
        action="copy-dir-recursively";
        src="$actualSisenseProgramData\PrismServer\ElastiCubeData";
        dest="$migrationDirRoot\ProgramData\Sisense\PrismServer\ElasticCubeData";
        create_dest_dir=$true;
        archive=$true;
        skip=$true
    },
    # backup Sisense Repository
    @{
        action="copy-dir-recursively";
        src="$actualSisenseProgramData\PrismWeb\Repository";
        dest="$migrationDirRoot\ProgramData\Sisense\PrismWeb\";
        create_dest_dir=$true;
        # skip=$true
    },
    # backup Sisense plugins
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
        cubeName="Sample ECommerce";
        skip=$true
    },
    @{
        action="start-elastiCube";
        cubeName="Sample Healthcare";
        skip=$true
    },
    @{
        action="start-elastiCube";
        cubeName="Sample Lead Generation";
        skip=$true
    },
    @{
        action="start-elastiCube";
        cubeName="DEV - Analytics";
        skip=$true
    },
    @{
        action="start-elastiCube";
        cubeName="Dev - Legacy Reports";
        skip=$true
    },
    @{
        action="start-elastiCube";
        cubeName="DEV - Pathfinder - BI";
        skip=$true
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
        serviceAction="start";
        skip=$true
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