<#
    FOR TESTING (AI Gen response / instructions, to be confirmed and implemented)
$array = @(
    [PSCustomObject]@{
        Name = "Object 1"
        Value = 10
    },
    [PSCustomObject]@{
        Name = "Object 2"
        Value = 20
    }
)
$array
#>


$AppName = ""; # Enter the name of the application (for logging, has no impact on deployment).
$AppVersion = [version]::Parse("1.0.0.0"); # Enter the version number of the application (as expected on the file).
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
    param ([string]$FilePath);
    if ($null -eq $FilePath) {
        return $null;
    }

    if (Test-Path -Path "$FilePath") {
        return Get-Item -Path "$FilePath";
    }

    return $null;
}


function Get-InstalledVersion {
    param ([FileInfo]$FileInfo);
    if ($null -ne $FileInfo) {
        return $FileInfo.VersionInfo.FileVersionRaw;
    }
    return $null;
}


function Get-InstallerIsNewer {
    param ([version]$InstalledVersion);
    if (($AppVersion -ne "") -or ($null -ne $null) -and $null -ne $InstalledVersion) {
        if ($AppVersion -gt $InstalledVersion) {
            return $true;
        }
    }
    return $false;
}


function Confirm-FileHash {
    param (
        [string]$FilePath,
        [string]$ExpectedHash
    );
}


function Get-FileFromURL {
    param (
        [string]$DownloadURL,
        [string]$DownloadHash,
        [string]$DownloadDest,
        [pscredential]$Credentials
    );

    if (($null -eq $DownloadURL) -or ($null -eq $DownloadDest)) {
        Invoke-WebRequest -Uri "$DownloadURL" -OutFile "$DownloadDest";
        #SEE EXAMPLE 8 ON https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.5
    }
}