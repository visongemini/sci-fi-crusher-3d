param(
  [int]$Port = 8788
)

$connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if (-not $connections) {
  Write-Host "Sci-Fi Crusher 3D server is not running."
  exit 0
}

$connections |
  Select-Object -ExpandProperty OwningProcess -Unique |
  ForEach-Object {
    Stop-Process -Id $_ -Force
    Write-Host "Stopped Sci-Fi Crusher 3D server. Process ID: $_"
  }
