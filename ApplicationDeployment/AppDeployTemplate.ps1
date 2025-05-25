$AppName = ""; # Enter the name of the application (for logging, has no impact on deployment).
$AppVersion = ""; # Enter the version number of the application (as expected on the file).
$AppSource = ""; # Enter the URL to download the installer from.
$AppSourceHash = ""; # Enter the MD5 hash for the downloaded file (for validation, NOT REQUIRED).
$AppInstallSwitches = "/qn /norestart"; # Application install switches, default for MSIs as "/qn /norestart"
$AppInstallValidation = ""; # Enter the path for file to test for to confirm installation (& version number checking).




param (
    [switch]$Force,
    [switch]$ReportOnly,
    [switch]$IfNotInstalled,
    [string]$Username,
    [string]$Password
)





function Get-Installed {
    param ([string]$FilePath)
    if ($null -eq $FilePath) {
        return $null;
    }

    if (Test-Path -Path "$FilePath") {
        return Get-Item -Path "$FilePath";;
    }

    return $null;
}


function Get-InstalledVersion {
    param ([FileInfo]$FileInfo)
    if ($null -ne $FileInfo) {
        return $FileInfo.VersionInfo.FileVersionRaw;
    }
    return $null;
}


function Get-InstallerIsNewer {
    if ($AppVersion -ne "" -or $AppVersion -ne $null) {

    }
    return $false;
}