#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root   = "C:\loki"
$LogDir = "$Root\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$InstallerUrl = "https://raw.githubusercontent.com/jameul-islam/promtail-config/main/installer-script"
$SanityUrl    = "https://raw.githubusercontent.com/jameul-islam/promtail-config/main/verify-install-script"

$InstallerPath = "$Root\install-endpoint.ps1"
$SanityPath    = "$Root\sanity-check.ps1"

Start-Transcript -Path "$LogDir\bootstrap.log" -Append | Out-Null

function Get-FileFromWeb($url, $out) {
  Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -MaximumRedirection 10 -Headers @{
    "User-Agent"="Mozilla/5.0"
    "Cache-Control"="no-cache"
    "Pragma"="no-cache"
  } -ErrorAction Stop

  if (-not (Test-Path $out) -or (Get-Item $out).Length -lt 200) {
    throw "Downloaded file looks wrong (missing/too small): $out"
  }

  $head = Get-Content $out -TotalCount 5 | Out-String
  if ($head -match "<html|<!DOCTYPE|503 Service") {
    throw "Downloaded content looks like an HTML error page, not a PowerShell script."
  }
}

try {
  Write-Host "Fetching installer..."
  Get-FileFromWeb $InstallerUrl $InstallerPath

  Write-Host "Running installer..."
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File $InstallerPath

  Write-Host "Fetching sanity check..."
  Get-FileFromWeb $SanityUrl $SanityPath

  Write-Host "Running sanitation check..."
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SanityPath

  Write-Host "✅ Completed. Logs in $LogDir"
}
finally {
  Stop-Transcript | Out-Null
}
