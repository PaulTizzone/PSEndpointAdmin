# Script Variables
$MirrorAuthUser = $null;
$MirrorAuthPass = $null;
$ProgressPreference = 'SilentlyContinue';

# Set up common use functions
function Get-FileFromURL {
    param (
        [Parameter(Mandatory=$true)]
        [String]$fileURL,
        [Parameter(Mandatory=$true)]
        [String]$outFile,
        [String]$fileHash
    )
    Invoke-WebRequest -Uri "$fileURL" -OutFile = "$outFile";
    if ($fileHash.Length -eq 32) { # MD5

    } elseif ($fileHash.Length -eq 40) { # SHA-1

    } elseif ($fileHash.Length -eq 64) { # SHA-256

    } elseif (($fileHash -eq "") -or ($null -eq $fileHash)) { # No hash provided - skip

    } else { #Invalid hash - error.
        # THROW EXCEPTION
    }
    
}
# Step-by-step Parts
#Part 1 - Download Required Files
#Part 2 - Run Required Files
#Part 3 - Validate Installation
#Part 4 - Cleanup