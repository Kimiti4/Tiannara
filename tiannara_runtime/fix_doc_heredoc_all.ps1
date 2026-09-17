Get-ChildItem -Path 'C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime\lib\tiannara_runtime' -Recurse -Filter *.ex | ForEach-Object {
    $original = Get-Content $_.FullName -Raw
    $content = $original
    # Remove UTF-8 BOM if present at start of file
    $content = $content -replace "^\uFEFF", ""
    # Fix @doc on same line with content and closing quotes
    $content = $content -replace '@doc\s+"""([^"\r\n]*)"""', '@doc """`n$1`n"""'
    # Fix empty @doc block where only opening triple quotes exist on the line
    $content = $content -replace '@doc\s+"""\s*$', '@doc """`n"""'
    if ($content -ne $original) {
        Set-Content -Path $_.FullName -Value $content -Encoding UTF8
        Write-Host "Updated $($_.FullName)"
    }
}
