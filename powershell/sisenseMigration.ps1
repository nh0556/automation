
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

function manageElastiCube {
    param( [string]$cubeName, [string]$action)
    
    $prismBaseCmd = "c:\Program Files\Sisense\prism\psm.exe"
            
    switch ($action) {
        "start" {
            $prismShellCommand = 'ecube start name="$cubeName"'
         }
         "stop" {
            $prismShellCommand = 'ecube stop name="' + $cubeName + '"'
         }
         "restart" {
            $prismShellCommand = 'ecube restart name="$cubeName"'
         }
    }

    # https://social.technet.microsoft.com/Forums/ie/en-US/7b398cea-0d29-4588-a6bc-ef793b51cc3c/run-a-dos-command-in-powershell?forum=winserverpowershell
    # $output = & "$prismBaseCmd" $prismShellCommand
    $output = Invoke-Expression -Command "$prismBaseCmd $prismShellCommand"

    write-host "$prismBaseCmd $prismShellCommand output:"
    write-host $output
    
}

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
        
    
    }
}



$migrationDirRoot = "c:\temp\sisenseMigration\run_{0}" -f (get-date).ToString("yyyy-MM-dd-hh-mm-ss")

# $runMode = "test"
# $array=@(@{src='C:\temp\test1'; action="copy-dir-recursively"; dest="c:\temp"; create_dest_dir=$true})

# createDirectory -dirName c:\temp\test2
# copyItem -src c:\temp\test1\sample.txt -dest c:\temp\test2
#copyItem -src c:\temp\test1 -dest c:\temp\test2 -recursive $true

$actualProgramFiles = (Get-ChildItem Env:ProgramFiles).value
$actualPFSisenseRoot = "$actualProgramFiles\Sisense"

$actualSisenseProgramData = "c:\ProgramData\Sisense"

$sisenseMigrationTasks=@(
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
    # backup elasticCubes
    @{
        action="copy-dir-recursively";
        src="$actualSisenseProgramData\PrismServer\ElastiCubeData";
        dest="$migrationDirRoot\ProgramData\PrismServer\ElasticCubeData";
        create_dest_dir=$true;
        archive=$true
    }
)

foreach($task in $sisenseMigrationTasks) {
    handleTask -task $task
}

Tree $migrationDirRoot /A /F