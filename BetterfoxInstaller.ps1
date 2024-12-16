Clear-Host

# Define the path to the Firefox Profiles directory
$profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"

# Define the URL to download the user.js file
$fileUrl = "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/user.js"

Write-Host "Betterfox User.js Installer"
Write-Host "This is an automated installer for yokoffing's Betterfox user.js mod for Firefox. It improves performance by 30% and makes Firefox better to use."
Write-Host "Press any key to begin!" -ForegroundColor "Yellow"
Read-Host

# Check if the Profiles directory exists
if (Test-Path $profilesPath) {
    # Get all directories in the Profiles folder
    $directories = Get-ChildItem -Path $profilesPath -Directory
		foreach ($directory in $directories) {
			# Define the full path for the user.js file
			$filePath = Join-Path -Path $directory.FullName -ChildPath "user.js"

			# Download the user.js file and save it in the directory
			Invoke-WebRequest -Uri $fileUrl -OutFile $filePath
		}
	Clear-Host
	Write-Host "Successfully downloaded and installed Betterfox user.js to all Firefox profiles in $profilesPath" -ForegroundColor Green
	Write-Host "Press any key to relaunch Firefox to apply the tweaks. Make sure all work is saved!"
	Read-Host
	TASKKILL /F /IM firefox.exe | Out-Null
	Start-Sleep -Seconds 1 | Out-Null
	Start-Process "$env:SystemDrive\Program Files\Mozilla Firefox\firefox.exe" | Out-Null
	Write-Host "Firefox has relaunched and the Betterfox tweaks are applied successfully. Press any key to exit."
	Read-Host
	exit
} else {
	Clear-Host
    Write-Host "Firefox is not installed, or is in an install location that is unsupported."
	Write-Host "Press any key to exit."
	Read-Host
	exit
}