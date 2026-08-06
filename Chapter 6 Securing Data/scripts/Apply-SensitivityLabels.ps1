<#
.SYNOPSIS
  Verifies, syncs, and (optionally) applies Microsoft Purview sensitivity labels
  on the 6 Chapter 6 sample files in the Wildpaws Expeditions Private SharePoint
  library, using Microsoft Graph.

.DESCRIPTION
  DLP #1 ("Block Copilot on Confidential") only fires when every Confidential
  file carries the EXACT SAME label GUID that the DLP rule targets, and when
  SharePoint has actually indexed that label. Two things break that in practice:

    1. The SharePoint "Sensitivity" column stays blank even after you label a
       file inside Word/Excel, because SharePoint hasn't refreshed its metadata
       from the file content yet.
    2. Files end up with a MIX of labels (e.g. "Confidential \ Anyone
       (unrestricted)" on one, "Confidential Pilot" on another). The DLP rule
       targets a single label, so any file with a different label is invisible
       to it and grounding proceeds normally.

  This script fixes both without the fragile path:

    * Default (Verify) mode calls driveItem: extractSensitivityLabels on each
      file. That forces SharePoint to read the label embedded in the file and
      refresh the "Sensitivity" column, AND returns the current label GUID so
      you can PROVE all four Confidential files carry one identical GUID before
      you retest DLP. This API needs only Files.Read.All and is NOT metered.

    * -Apply mode additionally calls driveItem: assignSensitivityLabel to force
      a consistent label onto every file. That API is METERED and PROTECTED:
      the tenant must have "metered APIs and services" enabled (an Azure
      subscription attached for billing) or the call fails. Prefer labeling the
      files by hand in Word/Excel to one identical label, then run this script
      in default Verify mode to confirm + sync. Use -Apply only if metered APIs
      are set up.

.PARAMETER SiteUrl
  Full URL to the SharePoint site. Default matches the Chapter 6 pilot site.

.PARAMETER LibraryName
  Document library display name. Default 'Documents' (the default library on a
  fresh communication/team site).

.PARAMETER ConfidentialLabelId
  GUID of the Confidential label the DLP #1 rule targets. Optional in Verify
  mode (used to name/validate the returned GUIDs); required with -Apply.

.PARAMETER GeneralLabelId
  GUID of the General label. Optional in Verify mode; required with -Apply.

.PARAMETER Apply
  Switch. When present, attempts to assign labels via the metered
  assignSensitivityLabel API before verifying. Omit for the safe, free path.

.PARAMETER GraphApiVersion
  'v1.0' or 'beta'. Defaults to 'v1.0' (both extract and assign are GA on v1.0).

.EXAMPLE
  # Safe path: sync the SharePoint column and prove label consistency
  .\Apply-SensitivityLabels.ps1 `
    -ConfidentialLabelId '00000000-0000-0000-0000-000000000000' `
    -GeneralLabelId      '11111111-1111-1111-1111-111111111111'

.EXAMPLE
  # Force one consistent label via Graph (needs metered APIs enabled)
  .\Apply-SensitivityLabels.ps1 -Apply `
    -ConfidentialLabelId '00000000-0000-0000-0000-000000000000' `
    -GeneralLabelId      '11111111-1111-1111-1111-111111111111'

.NOTES
  Requires Microsoft.Graph.Authentication (installed on demand).
  Verify mode consents: Files.Read.All, Sites.Read.All.
  -Apply mode also needs: Files.ReadWrite.All (or Sites.ReadWrite.All).
  Get the label GUIDs from Purview -> Information Protection -> Labels, or:
    Connect-IPPSSession
    Get-Label | Select-Object DisplayName, Guid
#>

[CmdletBinding()]
param(
    [string]$SiteUrl     = 'https://mngenvmcap198679.sharepoint.com/sites/WildpawsExpeditions',
    [string]$LibraryName = 'Documents',

    [string]$ConfidentialLabelId,
    [string]$GeneralLabelId,

    [switch]$Apply,

    [ValidateSet('v1.0', 'beta')]
    [string]$GraphApiVersion = 'v1.0'
)

$ErrorActionPreference = 'Stop'

# ---------- File -> expected category ----------
$Mapping = [ordered]@{
    'Wildpaws_VIP_Client_Roster_2026.docx'             = 'Confidential'
    'Wildpaws_Employee_Trail_1Expenses.xlsx'           = 'Confidential'
    'Wildpaws_Trip_Deposits_Ledger.xlsx'               = 'Confidential'
    'Wildpaws_Vendor_Invoice_BanffLodge_INV-2001.docx' = 'Confidential'
    'Wildpaws_Public_Trail_Catalog.docx'               = 'General'
    'Wildpaws_Packing_Guide_Pets.docx'                 = 'General'
}

# Expected GUID per category (only known if the caller passed them).
# NB: name must NOT case-collide with the loop's $expectedGuid variable.
$ExpectedGuidByCat = @{
    'Confidential' = $ConfidentialLabelId
    'General'      = $GeneralLabelId
}

if ($Apply -and (-not $ConfidentialLabelId -or -not $GeneralLabelId)) {
    throw "-Apply requires both -ConfidentialLabelId and -GeneralLabelId."
}

# ---------- Ensure Graph module ----------
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
    Write-Host "Installing Microsoft.Graph.Authentication for current user..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

# ---------- Connect ----------
$scopes = if ($Apply) {
    @('Files.ReadWrite.All', 'Sites.ReadWrite.All')
} else {
    @('Files.Read.All', 'Sites.Read.All')
}
Write-Host "Connecting to Microsoft Graph (scopes: $($scopes -join ', '))..." -ForegroundColor Cyan
Connect-MgGraph -Scopes $scopes -NoWelcome | Out-Null

$ctx = Get-MgContext
Write-Host "Signed in as $($ctx.Account) in tenant $($ctx.TenantId)" -ForegroundColor Green

# ---------- Resolve site -> drive ----------
$u        = [uri]$SiteUrl
$hostname = $u.Host
$sitePath = $u.AbsolutePath.TrimStart('/')   # sites/WildpawsExpeditions

Write-Host "`nResolving SharePoint site: $SiteUrl" -ForegroundColor Cyan
$site = Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/$GraphApiVersion/sites/${hostname}:/${sitePath}"
$siteId = $site.id
Write-Host "  Site: $($site.displayName)" -ForegroundColor Green
Write-Host "  ID:   $siteId"

Write-Host "`nLocating library '$LibraryName'..." -ForegroundColor Cyan
$drives = Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/$GraphApiVersion/sites/$siteId/drives"
$drive = $drives.value | Where-Object { $_.name -eq $LibraryName } | Select-Object -First 1
if (-not $drive) {
    $available = ($drives.value | ForEach-Object { $_.name }) -join ', '
    throw "Library '$LibraryName' not found. Available: $available"
}
$driveId = $drive.id
Write-Host "  Drive: $($drive.name)" -ForegroundColor Green
Write-Host "  ID:    $driveId"

# ---------- Helpers ----------
function Get-ItemByName {
    param([string]$FileName)
    $encoded = [uri]::EscapeDataString($FileName)
    try {
        return Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/$GraphApiVersion/drives/$driveId/root:/${encoded}" -ErrorAction Stop
    }
    catch {
        return $null   # 404 or other lookup failure; caller treats as not found
    }
}

function Get-LabelGuids {
    # Returns an array of non-empty sensitivity label GUIDs from an
    # extractSensitivityLabels response, tolerant of shape and nulls.
    param($Extract)
    $json = $Extract | ConvertTo-Json -Depth 8
    $obj  = $json | ConvertFrom-Json
    # Member access (not bracket indexing) returns $null silently when absent.
    $cands = @($obj.value.labels) + @($obj.labels)
    $ids = $cands |
        Where-Object { $_ -and $_.sensitivityLabelId } |
        ForEach-Object { [string]$_.sensitivityLabelId }
    return , @($ids)
}

function Invoke-Extract {
    param([string]$ItemId)
    # Forces SharePoint to refresh the Sensitivity column from file content and
    # returns the current label(s). Not metered; Files.Read.All is enough.
    return Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/$GraphApiVersion/drives/$driveId/items/$ItemId/extractSensitivityLabels"
}

function Invoke-Assign {
    param([string]$ItemId, [string]$LabelId)
    # METERED + PROTECTED. Returns 202 Accepted with a Location header; async.
    $body = @{
        sensitivityLabelId = $LabelId
        assignmentMethod   = 'standard'
        justificationText  = 'Applied via Graph for Chapter 6 DLP demo'
    } | ConvertTo-Json -Depth 4
    Invoke-MgGraphRequest -Method POST `
        -Uri "https://graph.microsoft.com/$GraphApiVersion/drives/$driveId/items/$ItemId/assignSensitivityLabel" `
        -Body $body -ContentType 'application/json' | Out-Null
}

function Resolve-LabelName {
    param([string]$Guid)
    if ($ConfidentialLabelId -and $Guid -eq $ConfidentialLabelId) { return 'Confidential' }
    if ($GeneralLabelId -and $Guid -eq $GeneralLabelId) { return 'General' }
    return '(unrecognized GUID)'
}

# ---------- Process ----------
# Each file is wrapped in its own try/catch so one bad response can't abort the
# whole run under $ErrorActionPreference='Stop'. No 'continue' inside a catch
# (that breaks the foreach in Windows PowerShell 5.1).
$results = @()
foreach ($fileName in $Mapping.Keys) {
    $expectedCat  = $Mapping[$fileName]
    $expectedGuid = $ExpectedGuidByCat[$expectedCat]
    Write-Host "`n--- $fileName (expected: $expectedCat) ---" -ForegroundColor Cyan

    $guid = ''
    $name = 'None'
    try {
        $item = Get-ItemByName -FileName $fileName
        if (-not $item) {
            Write-Warning "  Not found in library."
            $name = 'NotFound'
        }
        else {
            if ($Apply -and $expectedGuid) {
                try {
                    Write-Host "  Assigning $expectedCat label (metered API)..." -ForegroundColor Yellow
                    Invoke-Assign -ItemId $item.id -LabelId $expectedGuid
                    Write-Host "  Assign request accepted (async). Give it a few seconds." -ForegroundColor Green
                    Start-Sleep -Seconds 3
                }
                catch {
                    Write-Warning "  Assign failed: $($_.Exception.Message)"
                    Write-Warning "  If this mentions metering/billing, enable metered APIs or label this file by hand in Word/Excel."
                }
            }

            # Verify + sync. Refreshes the Sensitivity column and reads back.
            $extract = Invoke-Extract -ItemId $item.id
            $ids = Get-LabelGuids -Extract $extract
            if ($ids.Count -gt 0) {
                $guid = [string]$ids[0]
                $name = Resolve-LabelName -Guid $guid
            }
            else {
                $name = 'No label'
                $compact = ($extract | ConvertTo-Json -Depth 8 -Compress)
                if ($compact.Length -gt 400) { $compact = $compact.Substring(0, 400) + '...' }
                Write-Host "  (raw extract: $compact)" -ForegroundColor DarkGray
            }
        }
    }
    catch {
        Write-Warning "  Error processing this file: $($_.Exception.Message)"
        if ($name -eq 'None') { $name = 'Error' }
    }

    $match = $false
    if ($expectedGuid) {
        $match = ($guid -eq $expectedGuid)
    } elseif ($guid) {
        $match = $true   # no expected GUID passed; treat any label as present
    }

    $color = if ($match) { 'Green' } else { 'Red' }
    Write-Host "  Current label: $name  [$guid]" -ForegroundColor $color

    $results += [pscustomobject]@{
        File      = $fileName
        Expected  = $expectedCat
        LabelGuid = $guid
        LabelName = $name
        Match     = $match
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize File, Expected, LabelName, Match

# ---------- Consistency check ----------
$confGuids = @($results |
    Where-Object { $_.Expected -eq 'Confidential' -and $_.LabelGuid } |
    Select-Object -ExpandProperty LabelGuid -Unique)
if ($confGuids.Count -gt 1) {
    Write-Host "`nWARNING: Confidential files carry MORE THAN ONE label GUID:" -ForegroundColor Red
    $confGuids | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host "DLP #1 targets a single label, so it will only block the files whose GUID matches the rule." -ForegroundColor Red
    Write-Host "Re-label every Confidential file to ONE identical label, then re-run this script." -ForegroundColor Yellow
}
elseif ($confGuids.Count -eq 1) {
    Write-Host "`nAll labeled Confidential files share one GUID: $($confGuids[0])" -ForegroundColor Green
    Write-Host "Confirm DLP #1's rule condition (Content contains -> Sensitivity labels) targets THAT exact label." -ForegroundColor Yellow
}
else {
    Write-Host "`nNo Confidential files are labeled yet. Label them (Word/Excel or -Apply) before testing DLP #1." -ForegroundColor Red
}

Write-Host "`nRefresh the SharePoint library. The Sensitivity column should now be populated." -ForegroundColor Yellow
Write-Host "Then retest DLP #1 from '@Wildpaws Trail Guide' inside M365 Copilot chat (NOT the standalone Wildpaws bot)." -ForegroundColor Yellow
