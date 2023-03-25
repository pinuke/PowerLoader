param(
    [switch] $Reinstall = $false,
    [string] $ConfigFile,
    [string] $ProjectDir
)

$Root = If ( $Root ) { $Root } else {
    If ( $PSScriptRoot ) { Resolve-Path "$PSScriptRoot/../.." } else { Resolve-Path "./../.." }
}

$ProjectDir = If ( $ProjectDir ) { $ProjectDir } else {
    If ( $PSScriptRoot ) { Resolve-Path "$Root/.." } else { Resolve-Path "$Root/.." }
}

. "$Root/src/pwsh/helpers/ensure-glob.ps1"

. "$Root/src/pwsh/misc/native-library.ps1"
. "$Root/src/pwsh/misc/strings.ps1"
. "$Root/src/pwsh/misc/json.ps1"

$error.Clear() | Out-Null
$ConfigFile = Resolve-Path "$ProjectDir/powershell.json" -ErrorAction SilentlyContinue
If( $error ){
    $ConfigFile = Resolve-Path "$Root/src/json/default.json"
}

$Config = Import-Json $ConfigFile

If ( $Reinstall ) {
    foreach( $dir in $Config.Destinations.GetEnumerator() ){
        Remove-Item -Recurse -Force "$ProjectDir/$( $dir.Value )"
    }
}

If ( $Config.Dependencies ) {
    If ( $Config.Dependencies.Local ) {
        & "$Root/src/pwsh/dll/local.ps1" \
            -Dependencies $Config.Dependencies.Local
    } 
    If ( $Config.Dependencies.PSGallery ) {
        & "$Root/src/pwsh/dll/psgallery.ps1" \
            -Dependencies $Config.Dependencies.PSGallery \
            -SaveTo "$ProjectDir/$( $Config.Destinations.PSGallery )"
    }
    If ( $Config.Dependencies.NuGet ) {
        & "$Root/src/pwsh/dll/nuget.ps1" \
            -Dependencies $Config.Dependencies.NuGet \
            -SaveTo "$ProjectDir/$( $Config.Destinations.NuGet )"
    } 
}
