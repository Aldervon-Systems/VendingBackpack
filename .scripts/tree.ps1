Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$outFile = Join-Path (Get-Location) 'FILE_STRUCTURE.txt'
$output = New-Object System.Collections.Generic.List[string]

function Show-Tree([string]$path='.',[string]$prefix=''){
  $items = Get-ChildItem -Force -LiteralPath $path -ErrorAction Stop |
    Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name
  for ($i=0; $i -lt $items.Count; $i++) {
    $item = $items[$i]
    $isLast = ($i -eq $items.Count - 1)
    $connector = if ($isLast) { "`-- " } else { "|-- " }
    $output.Add($prefix + $connector + $item.Name) | Out-Null
    if ($item.PSIsContainer) {
      $newPrefix = $prefix + (if ($isLast) { '    ' } else { '|   ' })
      Show-Tree (Join-Path $path $item.Name) $newPrefix
    }
  }
}

$output.Add(".") | Out-Null
Show-Tree '.'
$output | Set-Content -Path $outFile -Encoding utf8
