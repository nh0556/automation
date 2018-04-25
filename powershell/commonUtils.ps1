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


function replaceFile {
    param( [string]$src, [string]$dest)

    if ((test-path $src) -and (test-path $dest)) {
        
        write-host "replacing $dest with $src"
        copy-item $src -Destination $dest -Force
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
        'replace-file' {
            write-host "replace file requested"

            if ($task.contains('backup') -and ($task.backup)) {
                $destFile = $task.dest
                write-host "backing up dest file, $destFile"

                # {0}" -f (get-date).ToString("yyyy-MM-dd-hh-mm-ss")
                $destFile = $destFile + ".bak-{0}"
                $destFile = $destFile -f (get-date).ToString("yyyy-MM-dd-hh-mm-ss")
                write-host "with backup, $destFile"
                copy-Item $task.dest -dest $destFile
            }

            $srcFile = $task.src
            $destFile = $task.dest

            copy-item $srcFile -dest $destFile -Force
            write-host "replaced $destFile with $srcFile"
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
        'unzip' {
            $srcArchive = $task.src
            $dest = $task.dest

            write-host "unzipping $srcArchive to $dest"
            Expand-Archive $srcArchive -DestinationPath $dest


            write-host "finished unzipping $srcArchive to $dest"


        }
    
    }
}
