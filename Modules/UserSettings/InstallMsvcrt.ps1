Set-StrictMode -Version 3.0

function InstallMsvcrt {

    Write-Host "[InstallMsvcrt] started ..." -ForegroundColor DarkYellow
    
    $items = @(
        "Microsoft.VCRedist.2015+.x86"
        "Microsoft.VCRedist.2015+.x64"
        "Microsoft.VCRedist.2013.x86"
        "Microsoft.VCRedist.2013.x64"
        "Microsoft.VCRedist.2012.x86"
        "Microsoft.VCRedist.2012.x64"
        "Microsoft.VCRedist.2010.x86"
        "Microsoft.VCRedist.2010.x64"
        "Microsoft.VCRedist.2008.x86"
        "Microsoft.VCRedist.2008.x64"
        "Microsoft.VCRedist.2005.x86"  
        "Microsoft.VCRedist.2005.x64"
    )

    foreach ($item in $items) {
        winget install --exact --silent --id $item
    }
}
