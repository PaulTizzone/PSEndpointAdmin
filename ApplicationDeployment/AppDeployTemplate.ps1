param (
    [switch]$ReportOnly,
    [switch]$IfNotInstalled,
    [switch]$Force,
    [switch]$Reinstall,
    [switch]$Uninstall
)

$WorkingDir = "C:\Temp\Deployment";

# Installers, or files to run (such as .sfx and other extractors) are executed in order of first to last.
# If you are extracting an executable file, place the self extractor first, then place the execution after (you only need to specify local location)
# Change the value to $null for values you are not using (optional values). Sample values have already been pre-filled.
$Installers = @(
    [PSCustomObject]@{
        AppName             = "Sample Application" # Name of the Application to install. (optional)
        SourceURL           = "https://download.path/file.exe" # Source URL to download the application from. (optional)
        SourceHash          = "" # MD5 hash for the downloaded file. (optional)
        FileDest            = "$WorkingDir\file.exe" # Location to download the file to.
        InstallSwitch       = "/qn /norestart" # Switches for the installer file. (required)
        InstallValidation   = "C:\Program Files\Path\To.exe" # Location to check for when done downloading file. (optional) [Also checks Version]
        $Version            = [version]::Parse("1.0.0.0"); # Windows .exe file version. (optional)
    }
);

# Additional files will be downloaded first, useful for configuration files or multi-part compressed files.
$AdditionalFiles = @(
    [PSCustomObject]@{
        SourceURL   = "" # Source URL to download the file from. (optional)
        SourceHash  = "" # MD5 hash for the downloaded file. (optional)
        FileDest    = "" # 
    }
);

$AdditionalCleanup = @(); # Add a list of strings with full file path to remove files after installation is complete (you can also add directories, will remove recursively with force).

function Uninstall-Application {
    # Enter uninstall commands here.
}



##########################################################################
####################        SCRIPT BEGINS HERE        ####################
##########################################################################
# You should not have to modify anything below this line unless making specific customisations.
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


function Test-InstallerIsNewer {
    param ([version]$InstalledVersion, [version]$AppVersion);
    if (($AppVersion -ne "") -or ($null -ne $AppVersion) -and $null -ne $InstalledVersion) {
        if ($AppVersion -gt $InstalledVersion) {
            return $true;
        }
    }
    return $false;
}


function Test-FileHash {
    param (
        [string]$FilePath,
        [string]$ExpectedHash
    );
    $LocalHash = Get-FileHash -Algorithm MD5 "$FilePath";
    return ($LocalHash -eq $ExpectedHash);
}


function Get-FileFromURL {
    param (
        [string]$DownloadURL,
        [string]$DownloadHash,
        [string]$DownloadDest
    );

    if (($null -eq $DownloadURL) -or ($null -eq $DownloadDest)) {
        Invoke-WebRequest -Uri "$DownloadURL" -OutFile "$DownloadDest";
        #SEE EXAMPLE 8 ON https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest?view=powershell-7.5
    }
}