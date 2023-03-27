param(
    [Parameter(Mandatory=$true)]
    [System.Management.Automation.OrderedHashtable] $Dependencies,
    [Parameter(Mandatory=$true)]
    [string] $SaveTo
)

foreach( $Dependency in $Dependencies.GetEnumerator() ){

    $CaseInsensitiveTable = [hashtable]::new( [System.StringComparer]::InvariantCultureIgnoreCase ) # Case Insensitive Table for Compatibility
    foreach ( $pair in $Dependency.Value.GetEnumerator() ) { $CaseInsensitiveTable[ $pair.Key ] = $pair.Value }

    $Dependency.Value = $CaseInsensitiveTable

    Write-Host
    Write-Host "Importing PowerShell Gallery Module:" -BackgroundColor DarkBlue -ForegroundColor White

    Ensure-Glob -Globs @( "$SaveTo/$( $Dependency.Name )/*/*.ps[md]1" ) `
        -EnsureScript {

            Write-Host "Downloading $( $Dependency.Name ), because it is missing..." -BackgroundColor DarkRed -ForegroundColor White
            $ProgressPreference = 'SilentlyContinue'
            Save-Module -Name $Dependency.Name -Path $SaveTo -Repository "PSGallery" -Force -ErrorAction Stop
            $ProgressPreference = 'Continue'
            Write-Host "$( $Dependency.Name ) downloaded." -BackgroundColor Green -ForegroundColor Black

        } `
        -SuccessScript {
            param( $Paths )

            If( !$Paths.Length -or ( $Paths -eq $null ) ){
                Write-Host " - no files loaded for this dependency"
                return;
            }

            Write-Host "Importing $( $Dependency.Name )..." -BackgroundColor DarkYellow -ForegroundColor White
            $Paths | ForEach-Object {
                Write-Host " - $( $_.Path )"
                Import-Module $_.Path
            }
        }
}