param (
    [string]$SourceFolder,
    [string]$PatchLetter,
    [string]$OutputFolder
)

# Path to MPQEditor.exe
$MPQEditor = "D:\Warcraft\Modding\MPQEditor.exe"

# Calculate the next power of 2
function Get-PowerOfTwo {
    param ([int]$n)
    $power = 1
    while ($power -lt $n) { $power *= 2 }
    return $power
}

# Check parameters
if (-not $SourceFolder -or -not $PatchLetter -or -not $OutputFolder) {
    Write-Host "Usage: .\build.ps1 -SourceFolder 'D:\path\to\localizations' -PatchLetter '<4-9, A-Z>' -OutputFolder 'D:\path\to\output'"
    exit
}

# Create Output Folder
if (!(Test-Path -Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder | Out-Null
}

Get-ChildItem -Path $SourceFolder -Directory | ForEach-Object {
    $Locale = $_.Name  # Name of the locale
    $MPQFile = "$OutputFolder\patch-$Locale-$PatchLetter.MPQ"
    $ScriptFile = "$OutputFolder\script-$Locale-$PatchLetter.txt"
    $LocaleFolder = $_.FullName

    $Files = Get-ChildItem -Path $LocaleFolder -Recurse -File
    $FileCount = $Files.Count
    $SlotCount = Get-PowerOfTwo -n $FileCount

    "new `"$MPQFile`" $SlotCount" | Out-File -Encoding utf8 $ScriptFile

    $Files | ForEach-Object {
        $RelativePath = $_.FullName.Substring($LocaleFolder.Length + 1) -replace "\\", "/"

        "add `"$MPQFile`" `"$($_.FullName)`" `"$RelativePath`" /auto /r"
    } | Out-File -Encoding utf8 -Append $ScriptFile

    "close `"$MPQFile`"" | Out-File -Encoding utf8 -Append $ScriptFile  

    Start-Process -NoNewWindow -Wait -FilePath $MPQEditor -ArgumentList "script `"$ScriptFile`""

    Write-Host "Created MPQ: $MPQFile (Slots count: $SlotCount, Files count: $FileCount)"
}

Write-Host "Done!"