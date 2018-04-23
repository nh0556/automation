##############################################################################
# Function definitions
##############################################################################

##############################################################################
# Creates a directory
##############################################################################
function createDirectory {
    param( [string]$dirName)

    write-host "requested $dirName to be created"

    if (-not (test-path $dirName)) {
        md $dirName | out-null
        write-host "requested $dirName created"
    } else {
        write-host  "$dirName already exists, skipping create!"
    }
}

##############################################################################
# Copies a directory or file
##############################################################################
function copyItem {
    param( [string]$src, [string]$dest, [bool]$recursive=$false)

    if (-not (test-path $src) -Or -not (test-path $dest)) {
        
        write-host "invalid $src or $dest, aborting"

    } else {
        
        if ($recursive) {
            copy-item $src -Destination $dest -Recurse
        } else {
            copy-item $src -Destination $dest
        }
    }
}

##############################################################################
# This function helps start/stop/restart Sisense ElastiCubes
#
# Actual working command: 
# & "c:\program files\sisense\prism\psm.exe" ecube stop name="Sample ECommerce"
#
# To make this invokeable using variables in powershell, args to the command
# are to be supplied in an array
#
# $stopCube = @('ecube', 'stop', 'name="Sample ECommerce"')
#
# Refer to stackoverflow article
# https://stackoverflow.com/questions/1673967
##############################################################################
function manageElastiCube {
    param( [string]$cubeName, [string]$action)
    
    $prismBaseCmd = "c:\Program Files\Sisense\prism\psm.exe"
    $cubeNameArg='"' + $cubeName + '"'

    switch ($action) {
        "start" {
            # psm ecube start name="{$cubeName}"
            $prismShellCommand = @('ecube', 'start', "name=$cubeNameArg")
         }
         "stop" {
            $prismShellCommand = @('ecube', 'stop', "name=$cubeNameArg")
         }
         "restart" {
            $prismShellCommand = @('ecube', 'start', "name=$cubeNameArg")
         }
    }

    $output = & "$prismBaseCmd" $prismShellCommand

    write-host "$prismBaseCmd $prismShellCommand output:"
    write-host $output
    
}

##############################################################################
# Wrapper function for starting/stopping services
##############################################################################
function manageService {
    param( [string]$serviceName, [string]$action)

    write-host "Attempting $action service, $serviceName"

    switch ($action) {
        "start" {
            $output = start-service -name $serviceName
         }
         "stop" {
            $output = stop-service -name $serviceName
         }
    }

    write-host "$action service, $serviceName Output: $output"
    
}

##############################################################################
# handleTask acts as the switch/dispatcher for tasks
# 
# Examines $task.action and based on the matching switch-case, dispatches
# the task to the actual task-handler function
##############################################################################
function handleTask {
    param( [hashtable]$task)
    
    $task_desc = $task.action

    Write-Host "Handling Task $task_desc"
    Write-Host "============================="
    $task
    Write-Host "============================="

    switch ($task.action) {
        'copy-file' {
            write-host "copy-file task requested"

            if ($task.create_dest_dir) {
                createDirectory -dirName $task.dest
            }

            write-host "copying $task.src to $task.dest"
            copyItem -src $task.src -dest $task.dest

        }
        'copy-dir-recursively' {
            write-host "copy-dir-recursively requested"

            if ($task.create_dest_dir) {
                createDirectory -dirName $task.dest
            }

            if ($task.archive) {
                Compress-Archive -Path $task.src -DestinationPath $task.dest
            } else {
                copyItem -src $task.src -dest $task.dest -recursive $true
            }
        }
        'stop-elastiCube' {
            
            manageElastiCube -cubeName $task.cubeName -action "stop"
        }
        'start-elastiCube' {
            
            manageElastiCube -cubeName $task.cubeName -action "start"
        }
        'restart-elastiCube' {
            
            manageElastiCube -cubeName $task.cubeName -action "restart"
        }
        'manage-service' {
            manageService -serviceName $task.serviceName -action $task.serviceAction
        }
    
    }
}

# Script starts here

$migrationDirRoot = "c:\temp\sisenseMigration\run_{0}" -f (get-date).ToString("yyyy-MM-dd-hh-mm-ss")

$actualProgramFiles = (Get-ChildItem Env:ProgramFiles).value
$actualPFSisenseRoot = "$actualProgramFiles\Sisense"

$actualSisenseProgramData = "c:\ProgramData\Sisense"

$sisenseMigrationTasks=@(
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
        dest="$migrationDirRoot\ProgramData\PrismServer\ElasticCubeData";
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