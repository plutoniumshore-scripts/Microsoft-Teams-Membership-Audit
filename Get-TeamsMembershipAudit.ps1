[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$UserPrincipalName,

    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'output')
)

<#
.SYNOPSIS
Audits Microsoft Teams memberships for a specified Microsoft 365 user.

.DESCRIPTION
Connects to Microsoft Graph using delegated interactive authentication, retrieves
Teams where the specified user is a direct member, displays the results, and
exports them to a timestamped CSV file.

The script performs read-only Microsoft Graph operations and requests the
Team.ReadBasic.All delegated permission.

Target environment: Microsoft 365 administration from Windows 11 using Windows
PowerShell 5.1 or PowerShell 7+.

.PARAMETER UserPrincipalName
The Microsoft 365 user principal name to audit. If omitted, the script prompts
for it interactively.

.PARAMETER OutputDirectory
Directory where the CSV report will be written. Defaults to an output folder
beside the script.

.EXAMPLE
.\Get-TeamsMembershipAudit.ps1 -UserPrincipalName 'user@example.com'

.EXAMPLE
.\Get-TeamsMembershipAudit.ps1 -UserPrincipalName 'user@example.com' -OutputDirectory 'C:\Reports'
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-RequiredModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not (Get-Module -ListAvailable -Name $Name | Select-Object -First 1)) {
        throw "Required module '$Name' is not installed. Install it with: Install-Module $Name -Scope CurrentUser"
    }
}

$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.Teams'
)

foreach ($moduleName in $requiredModules) {
    Assert-RequiredModule -Name $moduleName
}

if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) {
    $UserPrincipalName = Read-Host 'Enter the user UPN to audit (example: user@example.com)'
}

$UserPrincipalName = $UserPrincipalName.Trim()
if ([string]::IsNullOrWhiteSpace($UserPrincipalName)) {
    throw 'A user principal name is required.'
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Teams -ErrorAction Stop

$connected = $false

try {
    Write-Progress -Activity 'Microsoft Teams Membership Audit' -Status 'Connecting to Microsoft Graph' -PercentComplete 20

    Connect-MgGraph -Scopes 'Team.ReadBasic.All' -ContextScope Process -NoWelcome | Out-Null
    $connected = $true

    Write-Progress -Activity 'Microsoft Teams Membership Audit' -Status "Retrieving Teams for $UserPrincipalName" -PercentComplete 60

    $teams = @(Get-MgUserJoinedTeam -UserId $UserPrincipalName -All -ErrorAction Stop)

    $results = @(
        if ($teams.Count -gt 0) {
            foreach ($team in $teams) {
                [pscustomobject]@{
                    CheckedUserUpn  = $UserPrincipalName
                    MembershipFound = $true
                    TeamDisplayName = $team.DisplayName
                    TeamId          = $team.Id
                    TeamDescription = $team.Description
                    TeamIsArchived  = $team.IsArchived
                    TeamTenantId    = $team.TenantId
                }
            }
        }
        else {
            [pscustomobject]@{
                CheckedUserUpn  = $UserPrincipalName
                MembershipFound = $false
                TeamDisplayName = ''
                TeamId          = ''
                TeamDescription = ''
                TeamIsArchived  = $null
                TeamTenantId    = ''
            }
        }
    )

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $safeUser = $UserPrincipalName -replace '[^A-Za-z0-9._-]', '_'
    $csvPath = Join-Path $OutputDirectory ("TeamsMembership_{0}_{1}.csv" -f $safeUser, $timestamp)

    Write-Progress -Activity 'Microsoft Teams Membership Audit' -Status 'Exporting CSV report' -PercentComplete 90
    $results | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

    Write-Progress -Activity 'Microsoft Teams Membership Audit' -Completed -Status 'Complete'

    Write-Host ''
    Write-Host "Memberships found: $($teams.Count)"
    Write-Host "Report: $csvPath"
    Write-Host ''

    $results
}
finally {
    if ($connected) {
        try {
            Disconnect-MgGraph | Out-Null
        }
        catch {
        }
    }
}
