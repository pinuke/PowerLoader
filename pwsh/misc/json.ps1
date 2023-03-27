function global:Import-Json {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path
    )
    Get-Content -Path (Resolve-Path $Path) | ConvertFrom-Json -AsHashtable
}