# PowerShell script to read full context of all files
# Based on user memories - comprehensive file content reading

Write-Host "=== UNIVERSAL WEBCONTAINER - FULL FILE CONTEXT READER ===" -ForegroundColor Green
Write-Host "Reading all file contents in project..." -ForegroundColor Yellow

# Get all text-based files with comprehensive extensions
$textFiles = Get-ChildItem -Path . -Recurse -Include "*.swift", "*.h", "*.m", "*.mm", "*.c", "*.cpp", "*.js", "*.ts", "*.jsx", "*.tsx", "*.html", "*.css", "*.scss", "*.json", "*.md", "*.txt", "*.yml", "*.yaml", "*.plist", "*.xcconfig", "*.xml", "*.svg", "*.ps1", "*.sh", "*.py", "*.rb", "*.php", "*.java", "*.kt", "*.gradle", "*.sql", "*.csv", "*.tex", "*.bib", "*.bst", "*.cls", "*.sty", "*.dtx", "*.ins", "*.ltx", "*.aux", "*.log", "*.toc", "*.lof", "*.lot", "*.idx", "*.ind", "*.gls", "*.glo", "*.acn", "*.acr", "*.alg", "*.ist", "*.bbl", "*.blg", "*.fdb_latexmk", "*.fls", "*.synctex.gz", "*.out", "*.nav", "*.snm", "*.vrb", "*.xdv", "*.dvi", "*.ps", "*.eps", "*.rtf", "*.odt", "*.ods", "*.odp" | Where-Object { !$_.PSIsContainer }

Write-Host "Found $($textFiles.Count) text files to read" -ForegroundColor Cyan

# Read each file and display its content
foreach ($file in $textFiles) {
    Write-Host "`n" -NoNewline
    Write-Host "=== READING FILE: $($file.FullName) ===" -ForegroundColor Green
    Write-Host "File size: $([math]::Round($file.Length / 1KB, 2)) KB" -ForegroundColor Gray
    Write-Host "Last modified: $($file.LastWriteTime)" -ForegroundColor Gray
    
    try {
        # Read file content with encoding detection
        $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $content) {
            $content = Get-Content $file.FullName -Raw -Encoding Default -ErrorAction SilentlyContinue
        }
        
        if ($content) {
            Write-Host "Content:" -ForegroundColor Yellow
            Write-Host $content -ForegroundColor White
        } else {
            Write-Host " Could not read file content (possibly binary or empty)" -ForegroundColor Red
        }
    } catch {
        Write-Host " Error reading file: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "--- END OF FILE ---" -ForegroundColor DarkGray
    Write-Host "`n" -NoNewline
}

Write-Host "`n=== BINARY FILE ANALYSIS ===" -ForegroundColor Cyan

# List binary files without reading content
$binaryFiles = Get-ChildItem -Path . -Recurse -Include "*.ipa", "*.deb", "*.dylib", "*.framework", "*.bundle", "*.app", "*.exe", "*.dll", "*.so", "*.a", "*.lib", "*.o", "*.obj", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.tiff", "*.tif", "*.ico", "*.cur", "*.ani", "*.webp", "*.avif", "*.heic", "*.heif", "*.raw", "*.cr2", "*.nef", "*.arw", "*.orf", "*.rw2", "*.pef", "*.srw", "*.dng", "*.raf", "*.x3f", "*.mrw", "*.mef", "*.mos", "*.kdc", "*.dcr", "*.k25", "*.pdf", "*.zip", "*.tar", "*.gz", "*.7z", "*.rar", "*.dmg", "*.pkg", "*.apk", "*.msi", "*.deb", "*.rpm", "*.snap", "*.flatpak", "*.appimage" | Where-Object { !$_.PSIsContainer }

Write-Host "Found $($binaryFiles.Count) binary files:" -ForegroundColor White

foreach ($file in $binaryFiles) {
    Write-Host "  $($file.FullName) ($([math]::Round($file.Length / 1KB, 2)) KB)" -ForegroundColor Gray
}

Write-Host "`n=== SPECIAL FILES ANALYSIS ===" -ForegroundColor Cyan

# Analyze special project files
$specialFiles = @(
    "package.json",
    "README.md",
    "DEVELOPMENT_PLAN.md",
    "TODO_COMPLETE_CHECKLIST.md",
    "TODO_COMPREHENSIVE.md",
    "Universal WebContainer - Implementation Summary.md",
    "cursor_download_github_workflow_actions.md",
    "docker-compose.yml",
    "Dockerfile",
    ".gitignore"
)

foreach ($fileName in $specialFiles) {
    $file = Get-ChildItem -Path . -Recurse -Name $fileName -ErrorAction SilentlyContinue
    if ($file) {
        Write-Host "`n--- SPECIAL FILE: $fileName ---" -ForegroundColor Yellow
        try {
            $content = Get-Content $file -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content) {
                Write-Host $content -ForegroundColor White
            }
        } catch {
            Write-Host " Error reading special file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== PROJECT SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total text files read: $($textFiles.Count)" -ForegroundColor White
Write-Host "Total binary files found: $($binaryFiles.Count)" -ForegroundColor White
Write-Host "Total files analyzed: $($textFiles.Count + $binaryFiles.Count)" -ForegroundColor White

Write-Host "`n=== FULL CONTEXT READING COMPLETE ===" -ForegroundColor Green
