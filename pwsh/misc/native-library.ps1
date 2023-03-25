Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;

namespace Native
{
    public class Loaders
    {
        [DllImport("kernel32")]
        public static extern System.IntPtr LoadLibrary( System.String path );

        [DllImport("libdl")]
        public static extern System.IntPtr dlopen( System.String path, int flags );
    }
}
"@

function global:Import-NativeLibrary{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path
    )

    [System.IntPtr] $handle = [System.IntPtr]::Zero
    $handle = If ( $Env:OS -eq "Windows_NT" ) {
        [Native.Loaders]::LoadLibrary( $Path )
    } else {
        [Native.Loaders]::dlopen( $Path )
    }
    If ( $handle -eq [System.IntPtr]::Zero ) {
        throw [System.DllNotFoundException]::new(( Split-Path $Path -Leaf ))
    }

    $handle
}