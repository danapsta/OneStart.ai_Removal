# OneStart.ai_Removal

This repository contains PowerShell scripts for removing the OneStart.ai application.

`removeOneStartUnified.ps1` combines the logic from all previous scripts to terminate related processes,
remove files for all users, clean registry entries, and delete scheduled tasks. When something is found
and removed, the output line is displayed in **bold red** for quick visibility.

Run the script from an elevated PowerShell prompt:

```powershell
powershell -ExecutionPolicy Bypass -File .\removeOneStartUnified.ps1
```

Older scripts remain for reference.
