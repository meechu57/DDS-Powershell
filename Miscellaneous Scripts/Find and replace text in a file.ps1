# Define the file path and the strings to find and replace
$filePath = $env:pathToFile
$findText = $env:textToFind
$replaceText = $env:replacementText

# Backup the file before proceeding.
$backupPath = "$filePath.bak"
if (Test-Path $backupPath) {
  Remove-Item -Path $backupPath
  Write-Host "Previous backup deleted: $backupPath"
}

Copy-Item -Path $filePath -Destination $backupPath
Write-Host "Backup created: $backupPath"

# Read the file content.
$fileContent = Get-Content $filePath

# Show any matches
$matches = ($fileContent | Select-String -Pattern ([regex]::Escape($findText)) -AllMatches).Matches
if ($matches.Count -gt 0) {
  Write-Host "A match to '$findText' was found."
  Write-Host "Total matches: $($matches.Count)"
} else {
  Write-Host "No matches were found to '$findText'..."
  
  exit 1
}

Write-Host "Replacing found text..."
try {
  # Replace the text.
  $fileContent = $fileContent -replace [regex]::Escape($findText), $replaceText 
} catch {
  Write-Host "An error occurred when trying to replace the text in the '$filePath' file."
  
  exit 0
}

# Save the updated content back to the file.
Set-Content $filePath -Value $fileContent