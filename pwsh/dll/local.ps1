param(
    [Parameter(Mandatory=$true)]
    [string[]] $Dependencies
)

$Dependencies | ForEach-Object {
    Add-Type -AssemblyName $_
}