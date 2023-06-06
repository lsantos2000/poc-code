$rootFolder = Get-Location

# Function to update the created and modified dates of a file or folder
function Reset-Date($path) {
    $now = Get-Date
    (Get-Item $path).CreationTime = $now
    (Get-Item $path).LastWriteTime = $now
}

# Function to recursively reset dates for files and folders
function Recurse-Reset-Date($folderPath) {
    # Reset dates for files
    Get-ChildItem -File -Path $folderPath | ForEach-Object {
        Reset-Date $_.FullName
    }

    # Reset dates for folders
    Get-ChildItem -Directory -Path $folderPath | ForEach-Object {
        Reset-Date $_.FullName
        Recurse-Reset-Date $_.FullName
    }
}

Recurse-Reset-Date $rootFolder