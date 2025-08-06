<#
Unified OneStart Removal Script
Combines logic from removeOneStart.ps1, removeOneStart(test).ps1, and removeOneStart2025.ps1
#>

# Utility output functions for highlighting detected items
function Write-Detected {
    param([string]$Message)
    $esc = [char]27
    Write-Host "$esc[1m$Message$esc[0m" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

# Kill OneStart related processes
$processesToKill = @(
    @{ Name = 'DBar'; PathMatch = $null },
    @{ Name = 'OneStart'; PathMatch = 'C:\Users\*\AppData\Local\OneStart.ai\*' }
)

foreach ($p in $processesToKill) {
    if ($p.PathMatch) {
        $running = Get-CimInstance Win32_Process | Where-Object { $_.Name -like "$($p.Name)*" -and $_.ExecutablePath -like $p.PathMatch }
    } else {
        $running = Get-CimInstance Win32_Process -Filter "Name like '$($p.Name)%'"
    }
    if (-not $running) {
        Write-Info "No running processes found for $($p.Name)."
    } else {
        foreach ($proc in $running) {
            try {
                Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
                Write-Detected "Stopped $($p.Name) (PID $($proc.ProcessId))."
            } catch {
                Write-Detected "Failed to stop $($p.Name) (PID $($proc.ProcessId)): $_"
            }
        }
    }
}

Start-Sleep -Seconds 2

# Remove OneStart directories for all users
$filePaths = @(
    "AppData\Roaming\OneStart",
    "AppData\Local\OneStart.ai",
    "AppData\Local\OneStart*"
)
foreach ($user in Get-ChildItem C:\Users -Directory) {
    foreach ($fp in $filePaths) {
        $full = Join-Path $user.FullName $fp
        if (Test-Path $full) {
            try {
                Remove-Item -Path $full -Recurse -Force -ErrorAction Stop
                Write-Detected "Deleted $full"
            } catch {
                Write-Detected "Failed to delete $($full): $_"
            }
        }
    }
}

# Remove related registry keys from various hives
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software",
    "HKLM:\SOFTWARE"
)
foreach ($path in $registryPaths) {
    try {
        $keys = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'OneStart' }
        foreach ($key in $keys) {
            try {
                Remove-Item -Path $key.PSPath -Recurse -Force -ErrorAction Stop
                Write-Detected "Deleted registry key: $($key.PSPath)"
            } catch {
                Write-Detected "Failed to delete registry key: $($key.PSPath) - $_"
            }
        }
    } catch {
        Write-Info "Error accessing registry path: $path - $_"
    }
}

# Remove HKU OneStart.ai keys
foreach ($hive in Get-ChildItem Registry::HKEY_USERS) {
    $keyPath = "Registry::$($hive.PSChildName)\Software\OneStart.ai"
    if (Test-Path $keyPath) {
        try {
            Remove-Item -Path $keyPath -Recurse -Force -ErrorAction Stop
            Write-Detected "Removed registry key: $keyPath"
        } catch {
            Write-Detected "Failed to remove registry key: $keyPath - $_"
        }
    }
}

# Remove Run key properties
$runProps = @('OneStartBar', 'OneStartBarUpdate', 'OneStartUpdate')
foreach ($hive in Get-ChildItem Registry::HKEY_USERS) {
    $runKey = "Registry::$($hive.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $runKey) {
        foreach ($prop in $runProps) {
            try {
                Remove-ItemProperty -Path $runKey -Name $prop -ErrorAction Stop
                Write-Detected "Removed registry value $prop from $runKey"
            } catch {
                Write-Detected "Failed to remove registry value $prop from $runKey - $_"
            }
        }
    }
}

# Remove scheduled tasks explicitly named
$taskNames = @('OneStart Chromium', 'OneStart Updater')
$removed = 0
foreach ($task in $taskNames) {
    $existing = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
    if ($existing) {
        try {
            Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction Stop
            Write-Detected "Removed scheduled task: $task"
            $removed++
        } catch {
            Write-Detected "Failed to remove scheduled task: $task - $_"
        }
    }
}

# Remove any remaining tasks that match *OneStart*
Get-ScheduledTask | Where-Object { $_.TaskName -like '*OneStart*' } | ForEach-Object {
    try {
        Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction Stop
        Write-Detected "Removed scheduled task: $($_.TaskName)"
        $removed++
    } catch {
        Write-Detected "Failed to remove scheduled task: $($_.TaskName)"
    }
}

if ($removed -eq 0) {
    Write-Info 'No OneStart scheduled tasks were found.'
}

Write-Info 'Cleanup completed.'
