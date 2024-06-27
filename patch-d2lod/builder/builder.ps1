# Define an array of file names with ignore_crc set to true
$fileNamesToIgnoreCRC = @(
    "d2gl.ini",
    "d2fps.ini",
    "SGD2FreeResolution.json"
)

# Define an array of file names to exclude from manifest and HTML generation
$fileNamesToExclude = @(
    "index.html",
    "manifest.json"
)

# Remove previous type if already defined
if ([System.Management.Automation.PSTypeName]'CRC32'.Type) {
    Remove-TypeData -TypeName CRC32 -ErrorAction SilentlyContinue
    Remove-TypeData -TypeName CRC32 -ErrorAction SilentlyContinue
}

# Add the CRC32 class with corrected scope and accessibility
Add-Type -TypeDefinition @"
using System;
using System.IO;

public class CRC32 {
    uint[] table;

    public uint ComputeChecksum(byte[] bytes) {
        uint crc = 0xffffffff;
        for (int i = 0; i < bytes.Length; i++) {
            byte index = (byte)((crc & 0xff) ^ bytes[i]);
            crc = (crc >> 8) ^ table[index];
        }
        return ~crc;
    }

    public CRC32() {
        uint poly = 0xedb88320;
        table = new uint[256];
        for (int i = 0; i < 256; i++) {
            uint crc = (uint)i;
            for (int j = 8; j > 0; j--)
                crc = (crc & 1) == 1 ? (crc >> 1) ^ poly : crc >> 1;
            table[i] = crc;
        }
    }

    public string ComputeChecksumString(byte[] bytes) {
        return ComputeChecksum(bytes).ToString("x8");  // Output CRC in lowercase
    }
}
"@

# Function to compute CRC for a file
function Get-FileCRC {
    param (
        [string]$FilePath
    )

    $crcInstance = New-Object CRC32
    $fileData = [System.IO.File]::ReadAllBytes($FilePath)
    $crc = $crcInstance.ComputeChecksumString($fileData)
    $ignoreCRC = $false
    if ($fileNamesToIgnoreCRC -contains (Get-Item $FilePath).Name) {
        $ignoreCRC = $true
    }
    return @{
        name = (Get-Item $FilePath).Name  # Extract file name from full path
        crc = $crc
        last_modified = (Get-Item $FilePath).LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")
        content_length = (Get-Item $FilePath).Length
        ignore_crc = $ignoreCRC
        deprecated = $false
    }
}

# Function to generate HTML content for index.html file
function Generate-HTMLIndex {
    param (
        [string]$FolderPath,
        [array]$Files
    )

    $htmlContent = @"
<html>
<head><title>Index of $FolderPath</title></head>
<body>
<h1>Index of $FolderPath</h1><hr><pre>
<a href="../index.html">../</a>
"@
    foreach ($file in $Files) {
        if ($file.Name -notin $fileNamesToExclude) {
            $fileLink = if ($file.PSIsContainer) {
                $file.Name + "/"
            } else {
                $file.Name
            }
            $htmlContent += "<a href='$fileLink'>$($file.Name)</a>"
            if (-not $file.PSIsContainer) {
                $htmlContent += "`t`t`t$($file.LastWriteTime) `t`t`t$($file.Length)`n"
            } else {
                $htmlContent += "`n"
            }
        }
    }
    $htmlContent += "</pre><hr></body></html>"
    return $htmlContent
}

# Function to recursively process files in a folder
function Process-Folder {
    param (
        [string]$FolderPath
    )

    $files = Get-ChildItem -Path $FolderPath | Select-Object Name, LastWriteTime, Length, PSIsContainer
    $fileCRCs = $files | ForEach-Object {
        if (-not $_.PSIsContainer -and $_.Name -notin $fileNamesToExclude) {
            Get-FileCRC -FilePath "$FolderPath\$($_.Name)"
        }
    }

    # Save the manifest for the current folder
    $manifest = @{
        files = $fileCRCs
    }
    $manifest | ConvertTo-Json -Depth 100 | Set-Content -Path "$FolderPath\manifest.json" -Force

    # Generate HTML content for index.html file
    $htmlContent = Generate-HTMLIndex -FolderPath $FolderPath -Files $files
    $htmlContent | Set-Content -Path "$FolderPath\index.html" -Force

    # Recursively process subfolders
    $subfolders = Get-ChildItem -Directory -Path $FolderPath
    foreach ($subfolder in $subfolders) {
        Process-Folder -FolderPath $subfolder.FullName
    }
}

# Start processing from the current folder
Process-Folder -FolderPath (Get-Location).Path
