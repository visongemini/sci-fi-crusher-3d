param(
  [int]$Port = 8788,
  [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Url = "http://localhost:$Port/"

function Get-ContentType([string]$Path) {
  switch ([IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    '.html' { 'text/html; charset=utf-8' }
    '.js' { 'text/javascript; charset=utf-8' }
    '.css' { 'text/css; charset=utf-8' }
    default { 'application/octet-stream' }
  }
}

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "Sci-Fi Crusher 3D is running: $Url"
if (-not $NoBrowser) {
  Start-Process $Url
}

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII, $false, 1024, $true)
      $requestLine = $reader.ReadLine()
      while ($reader.ReadLine()) { }

      $target = 'index.html'
      if ($requestLine -match '^\w+\s+([^\s]+)') {
        $rawPath = [Uri]::UnescapeDataString($matches[1].Split('?')[0]).TrimStart('/')
        if ($rawPath) { $target = $rawPath }
      }

      $fullPath = [IO.Path]::GetFullPath([IO.Path]::Combine($Root, $target))
      if ($fullPath.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -and [IO.File]::Exists($fullPath)) {
        $body = [IO.File]::ReadAllBytes($fullPath)
        $status = '200 OK'
        $type = Get-ContentType $fullPath
      } else {
        $body = [Text.Encoding]::UTF8.GetBytes('Not found')
        $status = '404 Not Found'
        $type = 'text/plain; charset=utf-8'
      }

      $header = "HTTP/1.1 $status`r`nContent-Type: $type`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
      $headerBytes = [Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($headerBytes, 0, $headerBytes.Length)
      $stream.Write($body, 0, $body.Length)
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
