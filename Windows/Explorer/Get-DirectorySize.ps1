function Get-DirectorySize
{

  param(
    [Parameter(ValueFromPipeline)] [Alias('PSPath')]
    [string] $LiteralPath = '.',
    [switch] $Recurse,
    [switch] $ExcludeSelf,
    [int] $Depth = -1,
    [int] $__ThisDepth = 0 # internal use only
  )

  process {

    # Resolve to a full filesystem path, if necessary
    $fullName = if ($__ThisDepth) { $LiteralPath } else { Convert-Path -ErrorAction Stop -LiteralPath $LiteralPath }

    if ($ExcludeSelf) { # Exclude the input dir. itself; implies -Recurse

      $Recurse = $True
      $ExcludeSelf = $False

    } else { # Process this dir.

      # Calculate this dir's total logical size.
      # Note: [System.IO.DirectoryInfo].EnumerateFiles() would be faster, 
      # but cannot handle inaccessible directories.
      $size = [Linq.Enumerable]::Sum(
        [long[]] (Get-ChildItem -Force -Recurse -File -LiteralPath $fullName).ForEach('Length')
      )

      # Create a friendly representation of the size.
      $decimalPlaces = 2
      $padWidth = 8
      $scaledSize = switch ([double] $size) {
        {$_ -ge 1tb } { $_ / 1tb; $suffix='tb'; break }
        {$_ -ge 1gb } { $_ / 1gb; $suffix='gb'; break }
        {$_ -ge 1mb } { $_ / 1mb; $suffix='mb'; break }
        {$_ -ge 1kb } { $_ / 1kb; $suffix='kb'; break }
        default       { $_; $suffix='b'; $decimalPlaces = 0; break }
      }
  
      # Construct and output an object representing the dir. at hand.
      [pscustomobject] @{
        FullName = $fullName
        FriendlySize = ("{0:N${decimalPlaces}}${suffix}" -f $scaledSize).PadLeft($padWidth, ' ')
        Size = $size
      }

    }

    # Recurse, if requested.
    if ($Recurse -or $Depth -ge 1) {
      if ($Depth -lt 0 -or (++$__ThisDepth) -le $Depth) {
        # Note: This top-down recursion is inefficient, because any given directory's
        #       subtree is processed in full.
        Get-ChildItem -Force -Directory -LiteralPath $fullName |
          ForEach-Object { Get-DirectorySize -LiteralPath $_.FullName -Recurse -Depth $Depth -__ThisDepth $__ThisDepth }
      }
    }

  }

}



# Get the size of all child directories and sort them by size, from largest
# to smallest, showing only the 5 largest ones:
Get-DirectorySize -LiteralPath "D:\tools\hardware" -Depth 1 -ExcludeSelf | Sort-Object Size -Descending #| Select-Object -First 5