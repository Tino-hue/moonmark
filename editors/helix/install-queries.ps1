# MoonBit Highlight — Helix Query Installer (Windows)
# Run from repo root: .\editors\helix\install-queries.ps1

$RepoRoot = Resolve-Path "$PSScriptRoot\..\.."
$HelixRuntime = if ($env:HELIX_RUNTIME) {
    $env:HELIX_RUNTIME
} else {
    "$env:APPDATA\helix\runtime"
}

$TargetDir = "$HelixRuntime\queries\moonbit"

Write-Host "Installing MoonBit queries for Helix..."
Write-Host "  Source: $RepoRoot\queries"
Write-Host "  Target: $TargetDir"

New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

Copy-Item "$RepoRoot\queries\highlights.scm" "$TargetDir\"
Copy-Item "$RepoRoot\queries\indents.scm"    "$TargetDir\"
Copy-Item "$RepoRoot\queries\locals.scm"     "$TargetDir\"
Copy-Item "$RepoRoot\queries\injections.scm" "$TargetDir\"

Write-Host "Done! Run 'hx --grammar fetch' and 'hx --grammar build' to build the parser."
