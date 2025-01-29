# OneStart Removal Script

# Define valid paths for OneStart files
$valid_paths = @(
    "C:\Users\*\AppData\Roaming\OneStart\*",
    "C:\Users\*\AppData\Local\OneStart*\*"
)

# Define process names related to OneStart
$process_names = @("DBar")

foreach ($proc in $process_names) {
    $OL_processes = Get-Process -Name $proc -ErrorAction SilentlyContinue

    if (-not $OL_processes) {
        Write-Output "No running processes found for: $proc."
    } else {
        foreach ($process in $OL_processes) {
            try {
                Stop-Process -Id $process.Id -Force -ErrorAction Stop
                Write-Output "Process '$proc' (PID: $($process.Id)) has been stopped."
            } catch {
                Write-Output "Failed to stop process '$proc': $_"
            }
        }
    }
}

Start-Sleep -Seconds 2

# Remove OneStart directories for all users
$file_paths = @(
    "\AppData\Roaming\OneStart\",
    "\AppData\Local\OneStart.ai",
    "\AppData\Local\OneStart*\*"  # New path added
)

foreach ($userFolder in Get-ChildItem C:\Users -Directory) {
    foreach ($fpath in $file_paths) {
        $fullPath = Join-Path $userFolder.FullName $fpath
        if (Test-Path $fullPath) {
            try {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Output "Deleted: $fullPath"
            } catch {
                Write-Output "Failed to delete: $fullPath - $_"
            }
        }
    }
}

# Remove OneStart registry keys
$reg_paths = @("\Software\OneStart.ai")

foreach ($registry_hive in Get-ChildItem Registry::HKEY_USERS) {
    foreach ($regpath in $reg_paths) {
        $fullRegPath = "Registry::$($registry_hive.PSChildName)$regpath"
        if (Test-Path $fullRegPath) {
            try {
                Remove-Item -Path $fullRegPath -Recurse -Force -ErrorAction Stop
                Write-Output "Removed registry key: $fullRegPath"
            } catch {
                Write-Output "Failed to remove registry key: $fullRegPath - $_"
            }
        }
    }
}

# Remove OneStart registry properties from Run key
$reg_properties = @("OneStartBar", "OneStartBarUpdate", "OneStartUpdate")

foreach ($registry_hive in Get-ChildItem Registry::HKEY_USERS) {
    $runKeyPath = "Registry::$($registry_hive.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Run"
    
    if (Test-Path $runKeyPath) {
        foreach ($property in $reg_properties) {
            try {
                Remove-ItemProperty -Path $runKeyPath -Name $property -ErrorAction Stop
                Write-Output "Removed registry value: $property from $runKeyPath"
            } catch {
                Write-Output "Failed to remove registry value: $property from $runKeyPath - $_"
            }
        }
    }
}

# Remove scheduled tasks related to OneStart
$schtasknames = @("OneStart Chromium", "OneStart Updater")

$c = 0
foreach ($task in $schtasknames) {
    $clear_tasks = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue

    if ($clear_tasks) {
        try {
            Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction Stop
            Write-Output "Removed scheduled task: '$task'."
            $c++
        } catch {
            Write-Output "Failed to remove scheduled task: '$task' - $_"
        }
    }
}

if ($c -eq 0) {
    Write-Output "No OneStart scheduled tasks were found."
}
