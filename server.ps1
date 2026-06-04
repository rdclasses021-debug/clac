# Simple PowerShell HTTP Server for CalcPro Elite
$port = 3000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "Server started successfully on http://localhost:$port/"
    
    # Simple loop to process incoming HTTP requests
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $urlPath = $request.Url.LocalPath
        if ($urlPath -eq "/") {
            $urlPath = "/index.html"
        }
        
        # Resolve target file path (cleaning URL slashes for Windows compatibility)
        $cleanPath = $urlPath.Replace("/", "\").TrimStart("\")
        $localPath = Join-Path (Get-Location) $cleanPath
        
        if (Test-Path $localPath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            
            # Set appropriate MIME Content-Type
            $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
            $contentType = "text/plain"
            switch ($ext) {
                ".html" { $contentType = "text/html; charset=utf-8" }
                ".css"  { $contentType = "text/css; charset=utf-8" }
                ".js"   { $contentType = "application/javascript; charset=utf-8" }
                ".png"  { $contentType = "image/png" }
                ".svg"  { $contentType = "image/svg+xml" }
                ".json" { $contentType = "application/json" }
            }
            
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            
            # Disable caching for developer convenience
            $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
            
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
        }
        
        $response.OutputStream.Close()
    }
} catch {
    Write-Error "Error in Web Server: $_"
} finally {
    $listener.Close()
}
