Get-ChildItem -Path 'C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic\tiannara_runtime\lib\tiannara_runtime' -Recurse -Filter *.ex | ForEach-Object {
    $content = Get-Content $_ -Raw
    $new = $content -replace '@doc """([^\r\n]*)"""', '@doc """`n$1`n"""'
    if ($new -ne $content) {
        Set-Content -Path $_ -Value $new
    }
}
