function Get-FolderSize {
    param (
        [string]$path
    )

    if (Test-Path -Path $path -PathType Container) {
        $size = 0

        Get-ChildItem -Path $path -File -Recurse | ForEach-Object {
            $size += $_.Length
        }

        $sizeInMB = [math]::Round($size / 1MB, 2)
        $sizeInGB = [math]::Round($size / 1GB, 2)

        Return $sizeInMB
    } else {
        Write-Host "The path '$path' is not a valid directory."
    }
}

try 
{
    Set-Location ..\..\project-2-gang-of-four\

    # Get assets size   
    $assetSize = Get-FolderSize -path "Assets"

    # Run gc first
    Start-Process git -ArgumentList "gc" -NoNewWindow -Wait

    # Get output from counting
    $output = Invoke-Expression "git count-objects -vH"
    $outputLines = $output -split "`r`n"  # Split the output into lines
        $sizePackLine = $outputLines | Where-Object { $_ -match "size-pack:" }

        # Match the size pack line
        if ($sizePackLine -match "size-pack:\s*(\d+\.\d+\s*\w+)") 
        {
            $sizePack = $Matches[1]

            # Create an XML representation with only the value
            $xmlData = [xml]@"
                <RepoInfo>
                    <SizePack>$sizePack</SizePack>
                    <AssetSize>$assetSize MiB</AssetSize>
                </RepoInfo>
"@

            Set-Location ..\.github\gang-of-four-repo-size
            # Save the XML to a file
            $xmlData.Save("$(Get-Location)\\gof_repo_info.xml")
            Write-Host "Repository info updated in gof_repo_info.xml with Size Pack: $sizePack, Asset Size: $assetSize MiB"
        } 
        else 
        {
            Write-Host "Size Pack not found in the output."
        }
} 
catch 
{
    Write-Host "An error occurred: $($_.Exception.Message)"
}