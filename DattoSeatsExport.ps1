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
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath
$outputPath = Join-Path $scriptDir "Datto_SaaS_Seats.csv"

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
