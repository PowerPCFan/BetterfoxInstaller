Clear-Host

# Check if the script is running as an administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch the script as administrator
    $arguments = $myinvocation.MyCommand.Definition
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Unrestricted -File $arguments" -Verb RunAs
    Exit
}

# AnyBox
Install-Module -Name 'AnyBox' -RequiredVersion 0.5.1
Import-Module AnyBox

# Define the path to the Firefox Profiles directory
$profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"

# Define the URL to download the user.js file
$fileUrl = "https://raw.githubusercontent.com/yokoffing/Betterfox/refs/heads/main/user.js"

function installInAllProfiles {
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
}

function installInDefaultProfile {
	Invoke-WebRequest -Uri "https://raw.githubusercontent.com/PowerPCFan/BetterfoxInstaller/refs/heads/main/firefoxDefaultFinder.ps1" -OutFile "$env:Temp\firefoxDefaultFinder.ps1"
	Set-Location "$env:Temp"
    # Run the default profile detector script and capture the output
    $nameOfDefaultProfileFolder = (& ".\firefoxDefaultFinder.ps1").Trim()

    # Replace forward slashes with backslashes to construct a valid path
    $nameOfDefaultProfileFolder = $nameOfDefaultProfileFolder -replace '/', '\'

    # Define the Profiles directory path and the full path for the default profile
    $profilesPathNoProfiles = "$env:APPDATA\Mozilla\Firefox"
    $defaultProfilePath = Join-Path -Path $profilesPathNoProfiles -ChildPath $nameOfDefaultProfileFolder

    # Check if the default profile folder exists
    if (Test-Path $defaultProfilePath) {
        # Define the full path for the user.js file
        $filePath = Join-Path -Path $defaultProfilePath -ChildPath "user.js"

        # Download the user.js file and save it in the default profile
        try {
            Invoke-WebRequest -Uri $fileUrl -OutFile $filePath
            Write-Host "Successfully downloaded and installed Betterfox user.js to the default Firefox profile." -ForegroundColor Green
        } catch {
            Write-Host "Failed to download the user.js file. Error: $_" -ForegroundColor Red
            exit
        }

        # Prompt to relaunch Firefox
        Write-Host "Press any key to relaunch Firefox to apply the tweaks. Make sure all work is saved!"
        Read-Host

        # Close Firefox if it’s running
        TASKKILL /F /IM firefox.exe | Out-Null
        Start-Sleep -Seconds 1

        # Relaunch Firefox
        Start-Process "$env:ProgramFiles\Mozilla Firefox\firefox.exe" | Out-Null

        Write-Host "Firefox has relaunched and the Betterfox tweaks are applied successfully. Press any key to exit."
        Read-Host
        exit
    } else {
        Clear-Host
        Write-Host "The default profile folder does not exist: $defaultProfilePath" -ForegroundColor Red
        Write-Host "Press any key to exit."
        Read-Host
        exit
    }
}

function choiceBox {
        $anybox = New-Object AnyBox.AnyBox
		
        $anybox.Message = 'What profile would you like to install Betterfox in?'

        $anybox.Buttons = @(
            New-AnyBoxButton -Name 'all' -Text 'All Profiles'
            New-AnyBoxButton -Name 'default' -Text 'Default Profile'
        )

        # Show the AnyBox; collect responses.
        $response = $anybox | Show-AnyBox

        # Act on responses.
        if ($response['all'] -eq $true) {
			installInAllProfiles
        } elseif ($response['default'] -eq $true) {
			installInDefaultProfile
        }
    }

Write-Host "Betterfox User.js Installer"
Write-Host "This is an automated installer for yokoffing's Betterfox user.js mod for Firefox. It improves performance by 30% and makes Firefox better to use."
Write-Host "Press any key to begin!" -ForegroundColor "Yellow"
Read-Host
choiceBox