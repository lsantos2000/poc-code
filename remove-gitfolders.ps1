$rootPath = ".\"

# Function to recursively remove .git folders
function Remove-GitFolders {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    # Get all .git folders in the current directory
    $gitFolders = Get-ChildItem -Path $Path -Filter ".git" -Recurse -Directory

    # Remove each .git folder
    foreach ($folder in $gitFolders) {
        Write-Host "Removing Git folder: $($folder.FullName)"
        Remove-Item -Path $folder.FullName -Recurse -Force
    }
}

# Remove .git folders recursively from the root directory
Remove-GitFolders -Path $rootPath
