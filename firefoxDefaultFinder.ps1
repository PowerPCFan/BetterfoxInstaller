# Define the path to profiles.ini
$profilesIniPath = "$env:APPDATA\Mozilla\Firefox\profiles.ini"

# Check if the profiles.ini file exists
if (-Not (Test-Path -Path $profilesIniPath)) {
    Write-Output "none"
    exit
}

# Read the contents of profiles.ini
$profilesContent = Get-Content -Path $profilesIniPath -Raw

# Parse the contents of profiles.ini
$profilesSections = $profilesContent -split "\r?\n\r?\n"

# Initialize variables to hold the default profile folder
$defaultProfile = $null

foreach ($section in $profilesSections) {
    # Check for the [Install...] section
    if ($section -match "^\[Install") {
        # Extract the Default= value from the [Install...] section
        if ($section -match "Default=(.*)") {
            $defaultProfile = $Matches[1]
        }
        break
    }
}

# Output the default profile folder or "none" if not found
if ($defaultProfile) {
    Write-Output $defaultProfile
} else {
    Write-Output "none"
}
