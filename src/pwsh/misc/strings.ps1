function global:Import-Contents {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path
    )
    [string] $Contents = Get-Contet -Path (Resolve-Path $Path)
    $Contents
}