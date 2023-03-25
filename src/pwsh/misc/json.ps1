function global:Import-Json {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path
    )
    Get-Contet -Path (Resolve-Path $Path) | ConvertFrom-Json -AsHashtable
}