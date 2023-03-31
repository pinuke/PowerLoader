function global:Import-Contents {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path,
        [string] $As
    )
    [string] $Initial = Get-Content -Path (Resolve-Path $Path) -Raw

    switch ( $As ) {
        "scriptblock" {
            [scriptblock]::Create( $Initial )
        }
        "json" {
            $Initial | ConvertFrom-Json -AsHashtable            
        }
        Default {
            $Initial
        }
    }
}