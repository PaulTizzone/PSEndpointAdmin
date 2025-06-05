param (
    [switch]$ReportOnly,
    [switch]$IfNotInstalled,
    [switch]$Force,
    [switch]$Reinstall,
    [switch]$Uninstall
);

$WorkingDir = "C:\Temp\Deployment";

# Installers, or files to run (such as .sfx and other extractors) are executed in order of first to last.
# If you are extracting an executable file, place the self extractor first, then place the execution after (you only need to specify local location)
# Change the value to $null for values you are not using (optional values). Sample values have already been pre-filled.
$Installers = @(
    [PSCustomObject]@{
        AppName             = "Sample Application"; # Name of the Application to install. (optional)
        SourceURL           = "https://download.path/file.exe"; # Source URL to download the application from. (optional)
        SourceHash          = "00000000000000000000000000000000"; # MD5 hash for the downloaded file. (optional)
        FileDest            = "$WorkingDir\file.exe"; # Location to download the file to and what file to run (required)
        InstallSwitch       = "/qn /norestart"; # Switches for the installer file. (required)
        InstallValidation   = "C:\Program Files\Path\To.exe"; # Location to check for when done downloading file. (optional) [Also checks Version if specified]
        $Version            = [version]::Parse("1.0.0.0"); # Windows .exe file version. (optional)
    }
);

# Additional files will be downloaded first, useful for configuration files or multi-part compressed files.
$AdditionalFiles = @(
    [PSCustomObject]@{
        SourceURL   = "https://download.path/file.exe"; # Source URL to download the file from. (optional)
        SourceHash  = "00000000000000000000000000000000"; # MD5 hash for the downloaded file. (optional)
        FileDest    = "$WorkingDir\file.exe"; # 
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
    param ([FileInfo]$FileInfo);
    if ($null -ne $FileInfo) {
        Write-Output "Checking installed version...";
        return $FileInfo.VersionInfo.FileVersionRaw;
    }
    Write-Output "Installed version file not found.";
    return $null;
}


function Test-InstallerIsNewer {
    param ([version]$InstalledVersion, [version]$AppVersion);
    if (($AppVersion -ne "") -or ($null -ne $AppVersion) -and ($null -ne $InstalledVersion)) {
        Write-Output "Comparing new installer against installed file.";
        if ($AppVersion -gt $InstalledVersion) {
            Write-Output "Installer is a newer version.";
            return $true;
        }
        else {
            Write-Output "Installer is an older, or the same version.";
            return $false;
        }
    }
    Write-Output "Comparison not specified.";
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
    }
    elseif ($FilePath -like "*.msi") {
        Write-Output "File is an .msi installer. Proceeding with msiexec execution...";
        Start-Process msiexec -ArgumentList "/i `"$FilePath`" $FileSwitches" -Wait;
    }
    else {
        Write-Output "Unknown installer type.";
    }
}

### LOGIC BEGIN
if ($ReportOnly) {
    foreach ($Installer in $Installers) {
        if (Get-Installed -FilePath $Installer.InstallValidation) {
            $AppNameIs = $Installer.AppName;
            $InstalledVersionIs = Get-InstalledVersion -FileInfo 
            Write-Output "$AppNameIs is already installed as version ";
        }
    }
    exit 0;
}

# If the command is to simply uninstall, run uninstaller then exit.
if ($Uninstall) {
    Uninstall-Application;
    if (-not $Reinstall) {
        exit 0;
    }
}

# If the command is to re-install, run the uninstaller first then continue.
if ($Reinstall) {
    Uninstall-Application;
}


# LOGIC BEGIN
# Check if applications are installed before doing anything.
foreach ($Installer in $Installers) {

}