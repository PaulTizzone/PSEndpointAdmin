<#
Author:     Paul Tizzone
Version:    0.1 (05/06/2025)

Synopsis:
The motivation behind this installation script was to create an extremely re-usable template for installing applications on Windows 11 workstations using PowerShell.
With a few common install switches and an array of executable information, the idea here is to streamline app deployment to a large number of endpoints without having to create a new script each time or heavily modify a hard-coded template.
With this script, you specify a new object with preset variables and let it do its thing.
This was developed to solve an issue I faced with deploying some software that was either packed into an sfx extractor (I created myself) as it has a large amount of loose files that are required, or for software that requires dependencies that aren't packaged into the installer that have to be installed firsthand.




Notes:
This install script is currently being actively developed and cannot be used in its current state as a lot of the functionality has not been implemented yet.
I've been making and syncing commits as I am working on this file in my spare time on whatever device I have with me.

For loose files, simply create a self-extracting SFX archive (I use 7-zip), you can even split the archive into multiple files using the $AdditionalFiles array to download them (in the case of larger applications).
Then set the first $Installer object to be the SFX archive, with a InstallSwitch to extract the file. The following command works when running the self-extractor: -o"C:\Path\To\Directory"
Then set the second $Installer object to the actual Setup file (or any dependencies first). Just specify the FileDest and InstallSwitch as the rest would have been validated (you can also set a Hash to confirm file was successfully decompressed).
#>
param (
    [switch]$ReportOnly,
    [switch]$InstallMissing,
    [switch]$Force,
    [switch]$Reinstall,
    [switch]$Uninstall
);

##########################################################################
#################### MODIFY VARIABLES BELOW THIS LINE ####################
##########################################################################
$WorkingDir = "C:\Temp\Deployment"; # Specify the temporary / working directory. (Will make directory write for Administrators only!)

# Installers, or files to run (such as .sfx and other extractors) are executed in order of first to last.
# If you are extracting an executable file, place the self extractor first, then place the execution after (you only need to specify local location, not a download link, relative to the Working Dir)
# Change the value to $null for values you are not using (optional values). Sample values have already been pre-filled.
$Installers = @(
    [PSCustomObject]@{
        AppName             = "Sample Application" # Name of the Application to install. (optional)
        SourceURL           = "https://download.path/file.exe" # Source URL to download the application from. (optional)
        SourceHash          = "00000000000000000000000000000000" # MD5 hash for the downloaded file. (optional)
        FileDest            = "file.exe" # Location to download the file to and what file to run (required) [relative to WorkingDir]
        InstallSwitch       = "/qn /norestart" # Switches for the installer file. (required)
        InstallValidation   = "C:\Program Files\Path\To.exe" # Location to check for when done downloading file. (optional) [Also checks Version if specified]
        $Version            = [version]::Parse("1.0.0.0") # Windows .exe file version. (optional)
    }
);

# Additional files will be downloaded first, useful for configuration files or multi-part compressed files.
$AdditionalFiles = @(
    [PSCustomObject]@{
        SourceURL   = "https://download.path/file.exe" # Source URL to download the file from. (optional)
        SourceHash  = "00000000000000000000000000000000" # MD5 hash for the downloaded file. (optional)
        FileDest    = "file.exe" # 
    }
);

$AdditionalCleanup = @(); # Add a list of strings with full file path to remove files after installation is complete (you can also add directories, will remove recursively with force).

function Uninstall-Application {
    # Enter uninstall commands here. You can either specify the custom file and args, or search registry for the "QuietUninstallString" value if you specify part of (or the entire) name.
    <#$CustomUninstallFile = $null; # If you know the custom uninstall .exe file, enter it here, otherwise enter msiexec
    $CustomUninstallArgs = $null; # If you know the silent uninstall args, enter them here.
    $UninstallValidation = "C:\Prgram Files\Path\To\File.exe"; # Specify the file to check for when uninstalling.
    $SearchDisplayName = ""; # Search the registry for the display name (checks 32-bit and 64-bit). Can use wildcards.

    if (($null -ne $CustomUninstallFile) -and ($null -ne $CustomUninstallArgs)) {
        Start-Process $CustomUninstallFile -ArgumentList $CustomUninstallArgs;
    }
    else {
        Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName,QuietUninstallString,UninstallString | Where-Object {$_.DisplayName -like "$SearchDisplayName" };
    }

    if ($null -eq (Get-Installed -FilePath $UninstallValidation)) {
        Write-Output "Successfully uninstalled.";
    }
    else {
        Write-Output "Failed to uninstall!";
        exit 1;
    }#>
}



##########################################################################
####################        SCRIPT BEGINS HERE        ####################
##########################################################################
# You should not have to modify anything below this line unless making specific customisations.
$ProgressPreference = 'SilentlyContinue'; # This is changed to improve file download performance.


function Start-Environment {
    if (-not (Test-Path "$WorkingDir")) {
        Write-Output "Working Directory not found, creating $WorkingDir";
        New-Item -ItemType Directory -Path "$WorkingDir" -Force;
    }
    $env:temp = "$WorkingDir";
    Set-Location -Path "$WorkingDir";
    Write-Output "Now working out of $WorkingDir";
}


function Get-Installed {
    param ([string]$FilePath);
    if ($null -eq $FilePath) {
        Write-Output "File path not specified!."
        return $null;
    }
    Write-Output "Searching for $FilePath...";
    if (Test-Path -Path "$FilePath") {
        Write-Output "Found $FilePath.";
        return Get-Item -Path "$FilePath";
    }
    Write-Output "$FilePath not found!";
    return $null;
}


function Get-InstalledVersion {
    param ([System.IO.FileSystemInfo]$FileInfo);
    if ($null -ne $FileInfo) {
        Write-Output "Checking installed version...";
        return $FileInfo.VersionInfo;
    }
    Write-Output "Installed version file not found.";
    return $null;
}


function Test-InstallerIsNewer {
    param ([version]$InstalledVersion, [version]$AppVersion);
    if (($null -ne $AppVersion) -and ($null -ne $InstalledVersion)) {
        Write-Output "Comparing new installer against installed file.";
        if ($AppVersion -gt $InstalledVersion) {
            Write-Output "Installer is a newer version.";
            return $true;
        } else {
            Write-Output "Installer is an older, or the same version.";
            return $false;
        }
    }
    Write-Output "Comparison not specified.";
    return $false;
}


function Test-IsInstalled {
    param ($Inst)
    $AppNameIs = $Inst.AppName;
    if (Get-Installed -FilePath $Inst.InstallValidation) {
        $AppFileIs = Get-Installed -FilePath $Inst.InstallValidation;
        $InstalledVersionIs = (Get-InstalledVersion -FileInfo $AppFileIs).FileVersion;
        Write-Output "$AppNameIs is already installed as version $InstalledVersionIs";
        return (Get-InstalledVersion -FileInfo $AppFileIs.FileVersionRaw);
    } else {
        Write-Output "$AppNameIs is not installed.";
        return $null;
    }
}


function Test-FileHash {
    param (
        [string]$FilePath,
        [string]$ExpectedHash
    );
    $LocalHash = Get-FileHash -Algorithm MD5 "$FilePath";
    Write-Output "Expected Hash: $ExpectedHash";
    Write-Output "Local Hash: $LocalHash";
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
        if (Test-FileHash -FilePath "$DownloadDest" -ExpectedHash "$DownloadHash") { return $true; }
        else { return $false; }
    }
}


function Install-Application {
    param(
        [string]$FilePath,
        [string]$FileSwitches
    )
    if ($FilePath -like "*.exe") {
        Write-Output "File is an .exe installer. Proceeding with direct execution...";
        Start-Process -FilePath "$FilePath" -ArgumentList "$FileSwitches";
        Get-Process ($FilePath.Split("\")[-1].Replace(".exe","")) | Wait-Process;
    } elseif ($FilePath -like "*.msi") {
        Write-Output "File is an .msi installer. Proceeding with msiexec execution...";
        Start-Process msiexec -ArgumentList "/i `"$FilePath`" $FileSwitches" -Wait;
    } else {
        Write-Output "Unknown installer type.";
    }
}

### LOGIC BEGIN
Start-Environment;


if ($ReportOnly) {
    Write-Output "Reporting only.";
    foreach ($Installer in $Installers) {
        Test-IsInstalled -Inst $Installer;
    }
    exit 0;
}


# If the command is to simply uninstall, run uninstaller then exit.
if ($Uninstall -or $Reinstall) {
    Uninstall-Application;
    Write-Output "Finished uninstalling.";
    if (-not $Reinstall) {
        exit 0;
    }
}


# INSTALLATION BEGIN
# Check if applications are installed before doing anything.

foreach ($Installer in $Installers) {
    if ($Force) {
        Install-Application -FilePath $Installer.FileDest -FileSwitches $Installer.InstallSwitch;
    } else {
        $VersionInstalled = Test-IsInstalled -Inst $Installer;
        $CurName = $Installer.AppName;
        if ($null -eq $VersionInstalled) {
            Write-Output "$CurName not installed.";
            Install-Application -FilePath $Installer.FileDest -FileSwitches $Installer.InstallSwitch;
        } elseif (Test-InstallerIsNewer -InstalledVersion $VersionInstalled -AppVersion $Installer.Version) {
            if (-not $InstallMissing) {
                Write-Output "$CurName installer is newer than current version.";
                Install-Application -FilePath $Installer.FileDest -FileSwitches $Installer.InstallSwitch;
            } else {
                $VersionInstalledStr = $VersionInstalled.FileVersion;
                Write-Output "$CurName is already installed as version $VersionInstalledStr, skipping as InstallMissing switch is specified.";
            }
        } else {
            Write-Output "$CurName is the same or a later version than installer. Skipping.";
        }
    }
}