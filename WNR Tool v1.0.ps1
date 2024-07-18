<#
    Title: VxRail TOR Configuration Script Generator (VTCS-Gen) v1.0
    Copyright© 2024 Magdy Aloxory. All rights reserved.
    Contact: maloxory@gmail.com
#>

# Check if the script is running with administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch the script with administrator privileges
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Function to center text
function CenterText {
    param (
        [string]$text,
        [int]$width
    )
    
    $textLength = $text.Length
    $padding = ($width - $textLength) / 2
    return (" " * [math]::Max([math]::Ceiling($padding), 0)) + $text + (" " * [math]::Max([math]::Floor($padding), 0))
}

# Function to create a border
function CreateBorder {
    param (
        [string[]]$lines,
        [int]$width
    )

    $borderLine = "+" + ("-" * $width) + "+"
    $borderedText = @($borderLine)
    foreach ($line in $lines) {
        $borderedText += "|$(CenterText $line $width)|"
    }
    $borderedText += $borderLine
    return $borderedText -join "`n"
}

# Display script information with border
$title = "Window Network Routing Tool (WNR) v1.0"
$copyright = "Copyright 2024 Magdy Aloxory. All rights reserved."
$contact = "Contact: maloxory@gmail.com"
$maxWidth = 60

$infoText = @($title, $copyright, $contact)
$borderedInfo = CreateBorder -lines $infoText -width $maxWidth

Write-Host $borderedInfo -ForegroundColor Cyan

# Prompt user for input
$subnet = Read-Host "Enter the subnet you want to reach (e.g., 192.168.1.0)"
$mask = Read-Host "Enter the subnet mask (e.g., 255.255.255.0)"
$metric = "1"  # Metric is set to 1 as per your example command

# Get the default gateway for the Ethernet interface
$ethernetGateway = (Get-NetIPConfiguration | Where-Object { $_.InterfaceAlias -eq "Ethernet" }).IPv4DefaultGateway.NextHop

if (-not $ethernetGateway) {
    Write-Host "Could not find an active Ethernet gateway. Please check your network connection." -ForegroundColor Red
    exit
}

# Add the persistent route and capture the result
$routeCommand = "route -p add $subnet mask $mask $ethernetGateway metric $metric"
$routeResult = & cmd /c $routeCommand 2>&1

# Display the result
if ($routeResult -match "The route addition failed") {
    Write-Host "Failed to add route: $routeResult" -ForegroundColor Red
} elseif ($routeResult -match "The object already exists") {
    Write-Host "Route already exists: $routeResult" -ForegroundColor Yellow
} elseif ($routeResult -match "OK!") {
    Write-Host "Route added successfully: $subnet mask $mask via $ethernetGateway metric $metric" -ForegroundColor Green
} else {
    Write-Host "Unexpected result: $routeResult" -ForegroundColor Red
}

# Display Persistent Routes
$routePrintResult = & cmd /c "route print"
$persistRoutes = $routePrintResult -split "`n" | Select-String -Pattern "Persistent Routes" -Context 0,100

Write-Host "Persistent Routes:" -ForegroundColor Cyan
$persistRoutes.Context.DisplayPostContext | ForEach-Object { Write-Host $_ }

pause
