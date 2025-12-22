[CmdletBinding()]
param(
  [string]$BaseDir = $PSScriptRoot,
  [string]$StripPrefix = "exb-widgets_"
)

$ErrorActionPreference = 'Stop'

# List of widget repositories to sync. Add/remove URLs as needed.
$RepoUrls = @(
  "https://github.com/icil-aub/exb-widgets_Slider.git",
  "https://github.com/icil-aub/advancedButton.git",
  "https://github.com/icil-aub/exb-widgets_viewConesGenerator.git",
  "https://github.com/icil-aub/exb-widgets_constraints.git"
)


function Get-RepoNameFromUrl {
  param([string]$Url)

  if ([string]::IsNullOrWhiteSpace($Url)) {
    return $null
  }

  try {
    $leaf = Split-Path -Leaf ([Uri]$Url).AbsolutePath
  } catch {
    $leaf = Split-Path -Leaf $Url
  }

  if ($leaf.EndsWith(".git")) {
    $leaf = $leaf.Substring(0, $leaf.Length - 4)
  }

  if ([string]::IsNullOrWhiteSpace($leaf)) {
    return $null
  }

  return $leaf
}

function Normalize-RepoName {
  param(
    [string]$Name,
    [string]$PrefixToStrip
  )

  $result = $Name
  if (-not [string]::IsNullOrWhiteSpace($PrefixToStrip) -and
      $result.StartsWith($PrefixToStrip, [System.StringComparison]::OrdinalIgnoreCase)) {
    $result = $result.Substring($PrefixToStrip.Length)
    if ([string]::IsNullOrWhiteSpace($result)) {
      $result = $Name
    }
  }

  $result = $result -replace '[\\/:*?"<>|]', '-'
  return $result
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git not found in PATH. Install git or update PATH, then re-run."
  exit 1
}

if ([string]::IsNullOrWhiteSpace($BaseDir)) {
  $BaseDir = $PSScriptRoot
}
if (-not [IO.Path]::IsPathRooted($BaseDir)) {
  $BaseDir = Join-Path $PSScriptRoot $BaseDir
}
$BaseDir = [IO.Path]::GetFullPath($BaseDir)
New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null

if (-not $RepoUrls -or $RepoUrls.Count -eq 0) {
  Write-Error "No repository URLs configured in download-or-update-widgets.ps1."
  exit 1
}

$cloned = 0
$updated = 0
$skipped = 0
$failed = 0
$downloadedRepos = @()
$updatedRepos = @()

foreach ($url in $RepoUrls) {
  if ([string]::IsNullOrWhiteSpace($url)) {
    Write-Warning "Skipping empty repo url."
    $skipped++
    continue
  }

  $repoName = Get-RepoNameFromUrl -Url $url
  if (-not $repoName) {
    Write-Warning "Skipping invalid url: $url"
    $skipped++
    continue
  }

  $repoName = Normalize-RepoName -Name $repoName -PrefixToStrip $StripPrefix
  $target = Join-Path $BaseDir $repoName

  if (-not (Test-Path -LiteralPath $target)) {
    Write-Host "Cloning $url -> $target"
    git clone $url $target
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Clone failed (no access?): $url"
      $failed++
      continue
    }

    $cloned++
    $downloadedRepos += $repoName
    continue
  }

  if (-not (Test-Path -LiteralPath (Join-Path $target ".git"))) {
    Write-Warning "Skipping non-git directory: $target"
    $skipped++
    continue
  }

  $status = git -C $target status --porcelain
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Status check failed: $target"
    $failed++
    continue
  }
  if (-not [string]::IsNullOrWhiteSpace($status)) {
    Write-Warning "Local changes detected, skipping update: $target"
    $skipped++
    continue
  }

  Write-Host "Updating $target"
  git -C $target fetch --all --tags --prune
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Fetch failed (no access?): $target"
    $failed++
    continue
  }

  git -C $target pull --ff-only
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Pull failed: $target"
    $failed++
    continue
  }

  $updated++
  $updatedRepos += $repoName
}

if ($downloadedRepos.Count -gt 0) {
  Write-Host "Downloaded widgets:" -ForegroundColor Blue
  foreach ($repo in $downloadedRepos) {
    Write-Host (" - {0}" -f $repo) -ForegroundColor Blue
  }
} else {
  Write-Host "Downloaded widgets: none" -ForegroundColor Blue
}

if ($updatedRepos.Count -gt 0) {
  Write-Host "Updated widgets:" -ForegroundColor Blue
  foreach ($repo in $updatedRepos) {
    Write-Host (" - {0}" -f $repo) -ForegroundColor Blue
  }
} else {
  Write-Host "Updated widgets: none" -ForegroundColor Blue
}

Write-Host "Done. cloned=$cloned updated=$updated skipped=$skipped failed=$failed"
Read-Host "Press Enter to close"
