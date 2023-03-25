param(
    [Parameter(Mandatory=$true)]
    [hashtable] $Dependencies,
    [Parameter(Mandatory=$true)]
    [string] $SaveTo
)

foreach( $Dependency in $Dependencies.GetEnumerator() ){
    Write-Host
    Write-Host "Importing PowerShell Gallery Module:" -BackgroundColor DarkBlue -ForegroundColor White

    Ensure-Glob -Globs @( "$SaveTo/$( $Dependency.Name )/*/*.ps[md]1" ) `
        -EnsureScript {

            Write-Host "Downloading $( $Dependency.Name ), because it is missing..." -BackgroundColor DarkRed -ForegroundColor White
            $ProgressPreference = 'SilentlyContinue'
            Save-Module -Name $Dependency.Name -Path $SaveTo -Repository "PSGallery" -Force
            $ProgressPreference = 'Continue'
            Write-Host "$( $Dependency.Name ) downloaded." -BackgroundColor Green -ForegroundColor Black

        } `
        -SuccessScript {
            param( $Paths )

            Write-Host "Importing $( $Dependency.Name )..." -BackgroundColor DarkYellow -ForegroundColor White
            $Paths | ForEach-Object {
                Write-Host " - $( $_.Path )"
                Import-Module $_.Path
            }

            If( !$Targets.Length ){
                Write-Host " - no files loaded for this dependency"
            }
        }
}