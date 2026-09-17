Get-ChildItem -Path 'C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime\lib\tiannara_runtime' -Recurse -Filter *.ex | ForEach-Object {
    $path = $_.FullName
    $original = Get-Content $path -Raw -Encoding UTF8
    $content = $original
    # Remove UTF-8 BOM if present
    $content = $content -replace "^\uFEFF", ""
    # Ensure @doc opening triple quotes are on a line by themselves
    $content = $content -replace "@doc\s+\"\"\"", "@doc \"\"\"`n"
    # Ensure closing triple quotes are on their own line
    $content = $content -replace "\"\"\"\s*$", "`n\"\"\""
    if ($content -ne $original) {
        Set-Content -Path $path -Value $content -Encoding UTF8
        Write-Host "Updated $path"
    }
}
