# This takes the input from the script variable and sets the log file based on the run type of the script. 
switch ($env:scriptRunType) {
  "Ad Hoc" { $logPath = "C:\DDS\Logs\Scripts.log" }
  "Maintenance" { $logPath = "C:\DDS\Logs\Maintenance.log" }
  "Scheduled Automation" { $logPath = "C:\DDS\Logs\Scheduled Automation.log" }
  "Staging" { $logPath = "C:\DDS\Logs\Staging.log" }
  Default { Write-Host "An error occurred when trying to set the log pathway. Setting the log path to the default." ; $logPath = "C:\DDS\Logs\Scripts.log" }
}

# Get the operating system version
$osVersion = (Get-CimInstance Win32_OperatingSystem).Version

# Convert the script variable to a local variable. 
$enableDarkMode = $env:enableDarkMode

# Pull the currently logged in or last logged in user's SID.
$computerName = $env:COMPUTERNAME
$userName = (Get-WmiObject -Class win32_process -ComputerName $computerName | Where-Object name -Match explorer).getowner().user
$SID = (Get-WmiObject win32_useraccount | Select name,sid | Where-object {$_.name -like "$userName*"}).SID

# Find the active SID if there are two. (Local user)
if ($SID.count -gt 1) {
	Write-Host "More than 1 SID found. Finding the active SID."
	foreach ($ID in $SID) {
		if (Test-Path registry::HKEY_USERS\$ID) {
			$SID = $ID
			break
		}
	}
}

# Check if the OS version contains "10.0.2" (Windows 11)
if ($osVersion -like "10.0.2*") {
	# Create the main 5 registry keys if they don't exist. This should mainly only apply to the WindowsCopilot key.
	if (-not (Test-Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced)) {
		try {
			New-Item -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Force | Out-Null

			Write-Host "Created registry key: registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Created registry key: "
		} catch {
			Write-Host "Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced registry key: $_"

			exit 1
		}
	}
	if (-not (Test-Path registry::HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot)) {
		try {
			New-Item -Path registry::HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot -Force | Out-Null

			Write-Host "Created registry key: registry::HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Created registry key: registry::HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot"
		} catch {
			Write-Host "Failed to add the HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot registry key: $_"

			exit 1
		}
	}
	if (-not (Test-Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search)) {
		try {
			New-Item -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search -Force | Out-Null

			Write-Host "Created registry key: registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Created registry key: registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search"
		} catch {
			Write-Host "Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search registry key: $_"

			exit 1
		}
	}
	if (-not (Test-Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize)) {
		try {
			New-Item -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Force | Out-Null

			Write-Host "Created registry key: registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Created registry key: registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
		} catch {
			Write-Host "Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize registry key: $_"

			exit 1
		}
	}
	if (-not (Test-Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Start)) {
		try {
			New-Item -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Start -Force | Out-Null

			Write-Host "Created registry key: registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Start"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Created registry key: registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Start"
		} catch {
			Write-Host "Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Start registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to add the HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Start registry key: $_"

			exit 1
		}
	}

	#							Taskbar Configuration
	$taskView = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowTaskViewButton" -ErrorAction SilentlyContinue
	if ($taskView -eq $null -or $taskView.ShowTaskViewButton -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowTaskViewButton" -Value 0 -PropertyType DWord -Force
		} catch {
			Write-Host "Failed to set the ShowTaskViewButton registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the ShowTaskViewButton registry key: $_"
		}
	}
	
	$widgets = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarDa" -ErrorAction SilentlyContinue
	if ($widgets -eq $null -or $widgets.TaskbarDa -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarDa" -Value 0 -PropertyType DWord -Force
		} catch {
			Write-Host "Failed to set the TaskbarDa registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarDa registry key: $_"
		}
	}
	
	$chat = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarMn" -ErrorAction SilentlyContinue
	if ($chat -eq $null -or $chat.TaskbarMn -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarMn" -Value 0 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the TaskbarMn registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarMn registry key: $_"
	  }
	}

	$copilot = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot -Name "TurnOffWindowsCopilot" -ErrorAction SilentlyContinue
	if ($copilot -eq $null -or $copilot.TurnOffWindowsCopilot -ne 1) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Policies\Microsoft\Windows\WindowsCopilot -Name "TurnOffWindowsCopilot" -Value 1 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the TurnOffWindowsCopilot registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TurnOffWindowsCopilot registry key: $_"
	  }
	}

	$copilotTaskbar = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowCopilotButton" -ErrorAction SilentlyContinue
	if ($copilotTaskbar -eq $null -or $copilotTaskbar.ShowCopilotButton -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowCopilotButton" -Value 0 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the ShowCopilotButton registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the ShowCopilotButton registry key: $_"
	  }
	}

	$tbAlignment = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarAl" -ErrorAction SilentlyContinue
	if ($tbAlignment -eq $null -or $tbAlignment.TaskbarAl -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "TaskbarAl" -Value 0 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the TaskbarAl registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the TaskbarAl registry key: $_"
	  }
	}

	$search = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search -Name "SearchboxTaskbarMode" -ErrorAction SilentlyContinue
	if ($search -eq $null -or $search.SearchboxTaskbarMode -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Search -Name "SearchboxTaskbarMode" -Value 0 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the SearchboxTaskbarMode registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the SearchboxTaskbarMode registry key: $_"
	  }
	}

	#							Start Menu Configuration
	$startLayout = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Start_Layout" -ErrorAction SilentlyContinue
	if ($startLayout -eq $null -or $startLayout.Start_Layout -ne 1) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Start_Layout" -Value 1 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the Start_Layout registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the Start_Layout registry key: $_"
	  }
	}

	$infoTips = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowInfoTip" -ErrorAction SilentlyContinue
	if ($infoTips -eq $null -or $infoTips.ShowInfoTip -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "ShowInfoTip" -Value 0 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the ShowInfoTip registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the ShowInfoTip registry key: $_"
	  }
	}

	$irisTips = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Start_IrisRecommendations" -ErrorAction SilentlyContinue
	if ($irisTips -eq $null -or $irisTips.Start_IrisRecommendations -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "Start_IrisRecommendations" -Value 0 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the Start_IrisRecommendations registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the Start_IrisRecommendations registry key: $_"
	  }
	} 

	$visiblePlaces = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Start -Name "VisiblePlaces" -ErrorAction SilentlyContinue
	$expectedHex = ([byte[]]@(134, 8, 115, 82, 170, 81, 67, 66, 159, 123, 39, 118, 88, 70, 89, 212, 188, 36, 138, 20, 12, 214, 137, 66, 160, 128, 110, 217, 187, 162, 72, 130)  | ForEach-Object { "{0:X2}" -f $_ }) -join ' '
	if ($visiblePlaces) {
		$actualHex = ($visiblePlaces.VisiblePlaces | ForEach-Object { "{0:X2}" -f $_ }) -join ' '
		if ($actualHex -ne $expectedHex) {
			try {
				reg add "HKU\$SID\Software\Microsoft\Windows\CurrentVersion\Start" /v VisiblePlaces /t REG_BINARY /d 86087352AA5143429F7B2776584659D4BC248A140CD68942A0806ED9BBA24882 /f
		  } catch {
				Write-Host "Failed to set the VisiblePlaces registry key: $_"
				Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the VisiblePlaces registry key: $_"
		  }
		}
	}
	elseif ($visiblePlaces -eq $null) {
		try {
			reg add "HKU\$SID\Software\Microsoft\Windows\CurrentVersion\Start" /v VisiblePlaces /t REG_BINARY /d 86087352AA5143429F7B2776584659D4BC248A140CD68942A0806ED9BBA24882 /f
	  } catch {
			Write-Host "Failed to set the VisiblePlaces registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the VisiblePlaces registry key: $_"
	  }
	} 

	# Enable file name extensions
	$fileExtensions = Get-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "HideFileExt" -ErrorAction SilentlyContinue
	if ($fileExtensions -eq $null -or $fileExtensions.HideFileExt -ne 0) {
		try {
			New-ItemProperty -Path registry::HKEY_USERS\$SID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name "HideFileExt" -Value 0 -PropertyType DWord -Force
	  } catch {
			Write-Host "Failed to set the HideFileExt registry key: $_"
			Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to set the HideFileExt registry key: $_"
	  }
	}

  # Restarts Windows Explorer
  Stop-Process -Name explorer -Force
  Start-Sleep -Seconds 2
  Start-Process explorer
} 
else {
  Write-Host "A Windows 11 OS was not found. Aborting the script."
  Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") A Windows 11 OS was not found. Aborting the script."

  exit 1
}