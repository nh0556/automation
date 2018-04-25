##############################################################################
# Function definitions
##############################################################################

. .\commonUtils.ps1

# This powershell script deploys the contents of a given migration directory
# to an actual target Sisense

# Script starts here

$migrationDirRoot = "c:\temp\sisenseMigration\run_2018-04-24-05-20-03"

$actualProgramFiles = (Get-ChildItem Env:ProgramFiles).value
$actualPFSisenseRoot = "$actualProgramFiles\Sisense"

$actualSisenseProgramData = "c:\ProgramData\Sisense"

$targetSisenseProgramFilesRoot = "c:\temp\targetProgramFiles\Sisense"
$targetSisenseProgramDataRoot = "c:\temp\targetProgramData\Sisense"

$sisenseMigrationTasks=@(
    @{
        action="manage-service";
        serviceName="iisadmin";
        serviceAction="stop"
    },
    @{
        action="manage-service";
        serviceName="W3SVC";
        serviceAction="stop";
        skip=$true
    },
    @{
        action="manage-service";
        serviceName="Sisense.Repository";
        serviceAction="stop"
    },
    @{
        action="replace-file";
        src="$migrationDirRoot\Program Files\Sisense\PrismWeb\vnext\config\default.yaml"
        dest="$targetSisenseProgramFilesRoot\PrismWeb\vnext\config\default.yaml";
        backup=$true
    },
    @{
        action="replace-file";
        src="$migrationDirRoot\Program Files\Sisense\PrismWeb\App_Data\Configurations\db.config";
        dest="$targetSisenseProgramFilesRoot\PrismWeb\App_Data\Configurations\db.config";
        backup=$true
    },
    @{
        action="replace-file";
        src="$migrationDirRoot\Program Files\Sisense\Infra\MongoDB\mongodbconfig.conf";
        dest="$targetSisenseProgramFilesRoot\Infra\MongoDB\mongodbconfig.conf";
        backup=$true
    },
    # copy SSO configuration
    @{
        action="copy-file";
        src="$migrationDirRoot\Program Files\Sisense\PrismWeb\LoginSisense.ashx";
        dest="$targetSisenseProgramFilesRoot\PrismWeb\LoginSisense.ashx";
        backup=$true
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
    }
    # deploy elasticCubes from migration dir to target program data sisense root
    @{
        action="unzip";
        src="$migrationDirRoot\ProgramData\Sisense\PrismServer\ElasticCubeData.zip";
        dest="$targetSisenseProgramDataRoot\PrismServer\";
    },
    # deploy archived Sisense Plugins from migration dir to target dir
    @{
        action="copy-dir-recursively";
        src="$migrationDirRoot\Program Files\Sisense\PrismWeb\plugins";
        dest="$targetSisenseProgramFilesRoot\PrismWeb\";
    },
    # start ElastiCubes
    @{
        action="start-elastiCube";
        cubeName="Sample ECommerce";
    },
    @{
        action="start-elastiCube";
        cubeName="Sample Healthcare";
    },
    @{
        action="start-elastiCube";
        cubeName="Sample Lead Generation";
    },
    @{
        action="manage-service";
        serviceName="Sisense.Repository";
        serviceAction="start";
    },
    @{
        action="manage-service";
        serviceName="iisadmin";
        serviceAction="start";
    },
    @{
        action="manage-service";
        serviceName="W3SVC";
        serviceAction="start";
    }
)

foreach($task in $sisenseMigrationTasks) {
    if (-not ($task.contains('skip'))) {
        handleTask -task $task
    } else {
        write-host "!!! skipping " + $task.action
    }
}

Tree $targetSisenseProgramFilesRoot /A /F

# Tree $targetSisenseProgramDataRoot /A /F