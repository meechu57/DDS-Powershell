# The log path for this script.
#$logPath = "C:\DDS\Logs\Audit.log"

# All of the Backblaze buckets.
$buckets = @(
  "85West-Dental", "Anderson-Family-Dentistry", "Baker-Dental-Studio",
  "Baxter-Community-Center", "Beechtree-Family-Dentistry", "Belmont-Dentistry",
  "Big-Rapids", "Brian-Buurma", "Carroll-Family-Dentistry",
  "Chambers-Dental", "Clark-VanOverloop", "DDS-Integration2019",
  "Dentists-on-Eastcastle", "Dorr-Family-Dentistry", "Dyras-Dental",
  "Eric-Hull-DDS", "Erick-Perroud-DDS", "Family-Dentistry-Of-Caledonia-2024",
  "Forest-Hills-Endodontics", "Gaslight-Family-Dentistry", "Grady-Cosmetic-Dentistry",
  "Grand-River-Endo", "Grandville-DHC", "Grandville-Endo",
  "Greenville-Family-Dental", "HILARY-LANE-DDS-FAMILY-DENTISTRY", "Hastings-Family-Dental-Care",
  "Heather-H-Charchut", "Herrmann-DDS", "Hudsonville-Family-Dentistry",
  "Ivanrest-Family-Dentistry", "JCL-Perio", "Keefer-Family-Dentistry",
  "Kent-City-Dental-Center", "Knapp-Orthodontics", "Knowlton-Family-Dentistry",
  "Lange-Family-Dental-Care", "Langhorst-Family-Dentistry", "Lifetime-Eyecare",
  "Lowell-Dental-Care", "MI-Root-Family-Dental", "Mailloux-Dentistry",
  "Marshall-Family-Dentistry", "McDougal-Dental", "Meade-Zolman",
  "Michael-Miller-DDS", "Michael-P-Campeau-DDS", "Miller-Ortho",
  "Nichols-Family-Dentistry", "North-Park-Family-Dental", "Northview-Family-Dentistry",
  "OMSGGR-Alpine", "OMSGGR-Caledonia", "Paul-Winn-DDS",
  "Powell-Orthodontics", "Ravenna-Family-Dentistry", "Reed-City",
  "Richard-A-Oppenlander", "River-Ridge-Dentistry", "Rivertown-Dental",
  "Smith-Dental-Team", "Snyder-Family-Dentistry", "Sparta-Dental-Care",
  "Standale-Dental", "Stanton-Family-Dental-Care", "Strobel-Family-Dentistry",
  "Van-Timmeren-Family-Dentistry", "VanHaren-Dentistry", "VerMeulen-DDS",
  "Vitek-Family-Dentistry", "West-Michigan-Endodontists", "West-Michigan-Eyecare-Associates",
  "West-Michigan-Pediatric-Dentistry", "Westshore-Endo-Holland", "Westshore-Endodontics-Norton-Shores", 
  "esmiles", "posthumus-family-dentistry", "weidenfeller"
)

# Download the b2v3-windows.exe file.
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri "https://github.com/Backblaze/B2_Command_Line_Tool/releases/download/v4.1.0/b2v3-windows.exe" -OutFile "$env:temp/b2v3-windows.exe"
} catch {
  Write-Host "Failed to download the b2v3-windows.exe file: $_"
  #Add-Content -Path $logPath -Value "$(Get-Date -UFormat "%Y/%m/%d %T:") Failed to download the b2v3-windows.exe file: $_"

  exit 1
}

C:\Users\Brad\AppData\Local\Temp\b2v3-windows.exe account authorize 620624e105a9 00141484f95b992dac0e1e549e51187b3c2b17e587

foreach ($bucket in $buckets) {
	$repositories = C:\Users\Brad\AppData\Local\Temp\b2v3-windows.exe ls $bucket
	$files = C:\Users\Brad\AppData\Local\Temp\b2v3-windows.exe ls $bucket -r --long

	if ($repositories) {
		for ($i=1; $i -lt 5; $i++) {
			if (($repositories | Where-Object { $_ -match "^Repository$i-" }).count -gt 1) {
				Write-Host "Repository$i has more than 1 folder in Backblaze. Please investigate."
			}
		}
	}
}