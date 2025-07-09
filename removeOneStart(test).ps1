# This script has not been tested, but is an alternative for the new version of OneStart.  

# Define the target folder name
$targetFolder = "OneStart.ai"

# Step 1: Lookup and kill processes matching "onestart"
$processName = "onestart"
$processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

if ($processes) {
    foreach ($process in $processes) {
        Stop-Process -Id $process.Id -Force
        Write-Output "Killed process $($process.Name) with ID $($process.Id)"
    }
} else {
    Write-Output "No processes found matching $processName"
}

# Pause for 5 seconds
Start-Sleep -Seconds 10

# Step 2: Get all user profiles
$userProfiles = Get-ChildItem -Path "C:\Users" -Directory

# Step 3: Iterate through each user profile and delete target folder
foreach ($user in $userProfiles) {
    # Construct the full path to the target folder in AppData
    $folderPath = Join-Path -Path $user.FullName -ChildPath "AppData\Local\$targetFolder"
    
    # Check if the folder exists
    if (Test-Path -Path $folderPath) {
        # Remove the folder and its contents
        Remove-Item -Path $folderPath -Recurse -Force
        Write-Output "Deleted $folderPath"
    } else {
        Write-Output "Folder not found: $folderPath"
    }
}

# Step 4: Remove related registry keys
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software",
    "HKLM:\SOFTWARE"
)

foreach ($path in $registryPaths) {
    try {
        $keys = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "OneStart" }

        foreach ($key in $keys) {
            Remove-Item -Path $key.PSPath -Recurse -Force
            Write-Output "Deleted registry key: $($key.PSPath)"
        }
    } catch {
        Write-Output "Error accessing registry path: $path"
    }
}

# Step 5: Remove scheduled tasks related to OneStart.ai
$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "*OneStart*" }

foreach ($task in $tasks) {
    try {
        Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
        Write-Output "Deleted scheduled task: $($task.TaskName)"
    } catch {
        Write-Output "Failed to delete task: $($task.TaskName)"
    }
}

Write-Output "Cleanup completed."