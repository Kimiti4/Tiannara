Get-ChildItem -Path 'C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime\lib\tiannara_runtime' -Recurse -Filter *.ex | ForEach-Object {
    $path = $_.FullName
    $original = Get-Content $path -Raw -Encoding UTF8
    $content = $original
    # Remove UTF-8 BOM if present
    $content = $content -replace "^\uFEFF", ""
    # Replace any @doc triple-quoted block with proper multiline format
    $content = $content -replace "@doc\s+\"\"\"([\s\S]*?)\"\"\"", "@doc \"\"\"`n$1`n\"\"\""
    if ($content -ne $original) {
        Set-Content -Path $path -Value $content -Encoding UTF8
        Write-Host "Updated $path"
    }
}
