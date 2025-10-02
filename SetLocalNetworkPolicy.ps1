# Define registry paths
$edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
$chromeRegPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# Create registry keys if they don't exist
if (-not (Test-Path $edgeRegPath)) {
    New-Item -Path $edgeRegPath -Force | Out-Null
}
if (-not (Test-Path $chromeRegPath)) {
    New-Item -Path $chromeRegPath -Force | Out-Null
}

# Define allowed URLs as a comma-separated string
$allowedUrls = "https://factorylink-my.sharepoint.com,https://factorylink.sharepoint.com"

# Set the policy for Edge
Set-ItemProperty -Path $edgeRegPath -Name "LocalNetworkAccessAllowedForUrls" -Value $allowedUrls

# Set the policy for Chrome
Set-ItemProperty -Path $chromeRegPath -Name "LocalNetworkAccessAllowedForUrls" -Value $allowedUrls

Write-Host "Policy applied successfully for both Edge and Chrome."
