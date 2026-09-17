$files = Get-ChildItem -Path 'C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime\lib\tiannara_runtime' -Recurse -Filter *.ex
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    # Replace @doc with inline content
    $new = $content -replace '@doc\s+"""([^\r\n]*)"""', '@doc """`n$1`n"""'
    # Replace @doc with empty line (no content) that lacks closing quotes
    $new = $new -replace '@doc\s+"""\s*$', '@doc """`n"""'
    if ($new -ne $content) {
        Set-Content -Path $file.FullName -Value $new -Encoding UTF8
        Write-Host "Updated $($file.FullName)"
    }
}
