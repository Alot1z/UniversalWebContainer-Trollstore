# PowerShell script to list all files by type and show counts
# Based on user memories - comprehensive file analysis

Write-Host "=== UNIVERSAL WEBCONTAINER - FILE ANALYSIS ===" -ForegroundColor Green
Write-Host "Scanning all file types in project..." -ForegroundColor Yellow

# Get all files with comprehensive extensions
$files = Get-ChildItem -Path . -Recurse -Include "*.swift", "*.h", "*.m", "*.mm", "*.c", "*.cpp", "*.js", "*.ts", "*.jsx", "*.tsx", "*.html", "*.css", "*.scss", "*.json", "*.md", "*.txt", "*.yml", "*.yaml", "*.plist", "*.xcconfig", "*.xcworkspace", "*.xcodeproj", "*.ipa", "*.deb", "*.dylib", "*.framework", "*.bundle", "*.ps1", "*.sh", "*.py", "*.rb", "*.php", "*.java", "*.kt", "*.gradle", "*.xml", "*.svg", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.ico", "*.pdf", "*.zip", "*.tar", "*.gz", "*.7z", "*.rar", "*.dmg", "*.pkg", "*.app", "*.ipa", "*.apk", "*.exe", "*.msi", "*.deb", "*.rpm", "*.snap", "*.flatpak", "*.appimage", "*.dll", "*.so", "*.dylib", "*.a", "*.lib", "*.o", "*.obj", "*.s", "*.asm", "*.sql", "*.db", "*.sqlite", "*.sqlite3", "*.csv", "*.xlsx", "*.xls", "*.doc", "*.docx", "*.ppt", "*.pptx", "*.rtf", "*.odt", "*.ods", "*.odp", "*.tex", "*.bib", "*.bst", "*.cls", "*.sty", "*.dtx", "*.ins", "*.ltx", "*.aux", "*.log", "*.toc", "*.lof", "*.lot", "*.idx", "*.ind", "*.gls", "*.glo", "*.acn", "*.acr", "*.alg", "*.ist", "*.bbl", "*.blg", "*.fdb_latexmk", "*.fls", "*.synctex.gz", "*.out", "*.nav", "*.snm", "*.vrb", "*.xdv", "*.dvi", "*.ps", "*.eps", "*.pdf", "*.svg", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.tiff", "*.tif", "*.ico", "*.cur", "*.ani", "*.webp", "*.avif", "*.heic", "*.heif", "*.raw", "*.cr2", "*.nef", "*.arw", "*.orf", "*.rw2", "*.pef", "*.srw", "*.dng", "*.raf", "*.x3f", "*.mrw", "*.mef", "*.mos", "*.kdc", "*.dcr", "*.k25", "*.kc2", "*.kc3", "*.kc4", "*.kc5", "*.kc6", "*.kc7", "*.kc8", "*.kc9", "*.kc10", "*.kc11", "*.kc12", "*.kc13", "*.kc14", "*.kc15", "*.kc16", "*.kc17", "*.kc18", "*.kc19", "*.kc20", "*.kc21", "*.kc22", "*.kc23", "*.kc24", "*.kc25", "*.kc26", "*.kc27", "*.kc28", "*.kc29", "*.kc30", "*.kc31", "*.kc32", "*.kc33", "*.kc34", "*.kc35", "*.kc36", "*.kc37", "*.kc38", "*.kc39", "*.kc40", "*.kc41", "*.kc42", "*.kc43", "*.kc44", "*.kc45", "*.kc46", "*.kc47", "*.kc48", "*.kc49", "*.kc50", "*.kc51", "*.kc52", "*.kc53", "*.kc54", "*.kc55", "*.kc56", "*.kc57", "*.kc58", "*.kc59", "*.kc60", "*.kc61", "*.kc62", "*.kc63", "*.kc64", "*.kc65", "*.kc66", "*.kc67", "*.kc68", "*.kc69", "*.kc70", "*.kc71", "*.kc72", "*.kc73", "*.kc74", "*.kc75", "*.kc76", "*.kc77", "*.kc78", "*.kc79", "*.kc80", "*.kc81", "*.kc82", "*.kc83", "*.kc84", "*.kc85", "*.kc86", "*.kc87", "*.kc88", "*.kc89", "*.kc90", "*.kc91", "*.kc92", "*.kc93", "*.kc94", "*.kc95", "*.kc96", "*.kc97", "*.kc98", "*.kc99", "*.kc100" | Where-Object { !$_.PSIsContainer }

# Group by extension and sort by count
$fileGroups = $files | Group-Object Extension | Sort-Object Count -Descending

Write-Host "`n=== FILE TYPE ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Total files found: $($files.Count)" -ForegroundColor White
Write-Host "File types found: $($fileGroups.Count)" -ForegroundColor White

# Display file type summary
$fileGroups | Format-Table -Property @{Name="Count"; Expression={$_.Count}}, @{Name="Extension"; Expression={$_.Name}}, @{Name="Percentage"; Expression={[math]::Round(($_.Count / $files.Count) * 100, 1) + "%"}} -AutoSize

Write-Host "`n=== DETAILED FILE LISTING ===" -ForegroundColor Cyan

# Show detailed breakdown for each file type
foreach ($group in $fileGroups) {
    Write-Host "`n--- $($group.Name) Files ($($group.Count) files) ---" -ForegroundColor Yellow
    $group.Group | Select-Object -First 10 | ForEach-Object {
        Write-Host "  $($_.FullName)" -ForegroundColor Gray
    }
    if ($group.Count -gt 10) {
        Write-Host "  ... and $($group.Count - 10) more files" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== PROJECT STRUCTURE SUMMARY ===" -ForegroundColor Cyan
Write-Host "Directories:" -ForegroundColor White
Get-ChildItem -Path . -Directory | ForEach-Object {
    $dirCount = (Get-ChildItem -Path $_.FullName -Recurse -File | Measure-Object).Count
    Write-Host "  $($_.Name) ($dirCount files)" -ForegroundColor Gray
}

Write-Host "`n=== ANALYSIS COMPLETE ===" -ForegroundColor Green
