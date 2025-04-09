param(
    [Parameter(Mandatory = $true)]
    [string]$PublicKey,

    [Parameter(Mandatory = $true)]
    [string]$SecretKey
)

# ==== AUTH HEADER ====
$pair = "${PublicKey}:${SecretKey}"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)

$headers = @{
    Authorization = "Basic $base64"
    Accept        = "application/json"
}

$headers = @{
    Authorization = "Basic $base64"
    Accept        = "application/json"
}

# ==== LOCATION OF OUTPUT CSV ====
$IsWindows = $env:OS -eq 'Windows_NT'
$defaultFileName = "Datto_SaaS_Seats.csv"

if ($IsWindows) {
    try {
        Add-Type -AssemblyName System.Windows.Forms

        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select folder to save the Datto SaaS Backup CSV file"
        $folderBrowser.SelectedPath = [Environment]::GetFolderPath('Desktop')

        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $outputPath = Join-Path -Path $folderBrowser.SelectedPath -ChildPath $defaultFileName
        } else {
            Write-Host "❌ Cancelled. No folder selected."
            exit
        }
    }
    catch {
        Write-Warning "⚠️ Could not open folder dialog. Please enter a path manually."
        $manualPath = Read-Host "Enter folder path to save the CSV file (default: current directory)"
        if ([string]::IsNullOrWhiteSpace($manualPath)) {
            $manualPath = "."
        }
        $outputPath = Join-Path -Path $manualPath -ChildPath $defaultFileName
    }
}
else {
    Write-Host "💡 Non-Windows system detected. Using terminal prompt."
    $manualPath = Read-Host "Enter folder path to save the CSV file (default: current directory)"
    if ([string]::IsNullOrWhiteSpace($manualPath)) {
        $manualPath = "."
    }
    $outputPath = Join-Path -Path $manualPath -ChildPath $defaultFileName
}

# ==== BASE URL ====
$baseUrl = "https://api.datto.com/v1"

# ==== FETCH DOMAINS ====
$domains = Invoke-RestMethod -Uri "$baseUrl/saas/domains" -Headers $headers

# ==== COLLECT SEAT DATA ====
$allSeats = @()

foreach ($domain in $domains) {
    Write-Host "Processing: $($domain.saasCustomerName)..."

    $seatsUri = "$baseUrl/saas/$($domain.saasCustomerId)/seats"
    try {
        $seats = Invoke-RestMethod -Uri $seatsUri -Headers $headers
        foreach ($seat in $seats) {
            $allSeats += [PSCustomObject]@{
                CustomerName   = $domain.saasCustomerName
                Organization   = $domain.organizationName
                Domain         = $domain.domain
                ProductType    = $domain.productType
                MainId         = $seat.mainId
                Name           = $seat.name
                SeatType       = $seat.seatType
                SeatState      = $seat.seatState
                Billable       = $seat.billable
                DateAdded      = $seat.dateAdded
            }
        }
    } catch {
        Write-Warning "Failed to fetch seats for $($domain.saasCustomerName) (ID: $($domain.saasCustomerId)): $($_.Exception.Message)"
    }
}

# ==== EXPORT TO CSV ====
$allSeats | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
Write-Host "✅ Exported to $outputPath"
