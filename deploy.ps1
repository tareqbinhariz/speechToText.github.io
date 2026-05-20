# Aswat - Ultimate Build, Commit & Deploy Script
# Performs: Ask Commit Msg -> Flutter Clean -> Pub Get -> Build Web -> Sync Assets -> Git Add All -> Git Commit -> Git Push

$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "        ASWAT PRODUCTION DEPLOYER                 " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# ----------------------------------------------------------------------
# 1. Retrieve Commit Message FIRST (With Premium GUI & Console Fallbacks)
# ----------------------------------------------------------------------
Function Get-CommitMessage {
    $commitMessage = ""
    $useGUI = $true

    # Try loading Windows Forms for a gorgeous GUI popup
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    } catch {
        $useGUI = $false
    }

    if ($useGUI) {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Aswat Deployer - Commit & Deploy"
        $form.Size = New-Object System.Drawing.Size(650, 480)
        $form.StartPosition = "CenterScreen"
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 46) # Catppuccin Mocha Crust
        $form.TopMost = $true

        # Title Label
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Location = New-Object System.Drawing.Point(25, 20)
        $titleLabel.Size = New-Object System.Drawing.Size(600, 30)
        $titleLabel.Text = "Prepare Commit & Deployment"
        $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(137, 220, 235) # Pastel Cyan
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 13, ([System.Drawing.FontStyle]::Bold))
        $form.Controls.Add($titleLabel)

        # Subtitle Label
        $instrLabel = New-Object System.Windows.Forms.Label
        $instrLabel.Location = New-Object System.Drawing.Point(25, 55)
        $instrLabel.Size = New-Object System.Drawing.Size(600, 25)
        $instrLabel.Text = "Paste or type your commit message below. Multi-line text is fully supported."
        $instrLabel.ForeColor = [System.Drawing.Color]::FromArgb(186, 194, 222) # Soft lavender gray
        $instrLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
        $form.Controls.Add($instrLabel)

        # Multi-line Text Box
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Location = New-Object System.Drawing.Point(25, 90)
        $textBox.Size = New-Object System.Drawing.Size(585, 270)
        $textBox.MultiLine = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 37) # Darker Slate bg
        $textBox.ForeColor = [System.Drawing.Color]::FromArgb(205, 214, 244) # Smooth white text
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 10.5)
        $textBox.BorderStyle = "FixedSingle"
        
        # Auto-detect Clipboard text to make it effortless
        try {
            $clipText = Get-Clipboard -Raw
            if ($clipText -and $clipText.Trim() -ne "") {
                $textBox.Text = $clipText
                $textBox.SelectionStart = $textBox.Text.Length
            }
        } catch {
            $null = $error[0]
        }
        $form.Controls.Add($textBox)

        # Deploy Button (Pastel Green)
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Location = New-Object System.Drawing.Point(350, 380)
        $btnOK.Size = New-Object System.Drawing.Size(120, 40)
        $btnOK.Text = "Start Deploy"
        $btnOK.FlatStyle = "Flat"
        $btnOK.BackColor = [System.Drawing.Color]::FromArgb(166, 227, 161)
        $btnOK.ForeColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
        $btnOK.Font = New-Object System.Drawing.Font("Segoe UI", 10, ([System.Drawing.FontStyle]::Bold))
        $btnOK.Cursor = ([System.Windows.Forms.Cursors]::Hand)
        $btnOK.DialogResult = ([System.Windows.Forms.DialogResult]::OK)
        $form.AcceptButton = $btnOK
        $form.Controls.Add($btnOK)

        # Cancel Button (Pastel Coral/Red)
        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Location = New-Object System.Drawing.Point(490, 380)
        $btnCancel.Size = New-Object System.Drawing.Size(120, 40)
        $btnCancel.Text = "Cancel"
        $btnCancel.FlatStyle = "Flat"
        $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(243, 139, 168)
        $btnCancel.ForeColor = [System.Drawing.Color]::FromArgb(17, 17, 27)
        $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 10, ([System.Drawing.FontStyle]::Bold))
        $btnCancel.Cursor = ([System.Windows.Forms.Cursors]::Hand)
        $btnCancel.DialogResult = ([System.Windows.Forms.DialogResult]::Cancel)
        $form.CancelButton = $btnCancel
        $form.Controls.Add($btnCancel)

        $result = $form.ShowDialog()
        if ($result -eq ([System.Windows.Forms.DialogResult]::OK)) {
            $commitMessage = $textBox.Text
        } else {
            Write-Host "[INFO] Deployment cancelled by user!" -ForegroundColor Yellow
            Exit 0
        }
    } else {
        # Console Fallback - Highly resilient multi-line paste parser
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "   ENTER / PASTE YOUR COMMIT MESSAGE " -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "* Emojis and multiple lines are fully supported." -ForegroundColor Gray
        Write-Host "* When finished, type 'DONE' on a new line and press Enter." -ForegroundColor Yellow
        Write-Host "* Type 'EXIT' to cancel deployment." -ForegroundColor Red
        Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
        
        $lines = @()
        while ($true) {
            $line = Read-Host
            if ($null -eq $line) { break }
            if ($line.Trim().ToUpper() -eq "DONE") {
                break
            }
            if ($line.Trim().ToUpper() -eq "EXIT") {
                Write-Host "[INFO] Deployment cancelled by user!" -ForegroundColor Yellow
                Exit 0
            }
            $lines += $line
        }
        $commitMessage = $lines -join "`n"
    }

    if ($commitMessage.Trim() -eq "") {
        Write-Host "[ERROR] Commit message cannot be empty! Deployment aborted." -ForegroundColor Red
        Exit 1
    }

    return $commitMessage
}

# Always prompt user immediately at startup
$commitMessage = Get-CommitMessage

Write-Host "[INFO] Stored Commit Message:" -ForegroundColor Cyan
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
Write-Host $commitMessage -ForegroundColor Gray
Write-Host "--------------------------------------------------" -ForegroundColor DarkGray

# ----------------------------------------------------------------------
# 2. Flutter Rebuild Pipeline
# ----------------------------------------------------------------------
try {
    Write-Host "[1/4] Running Flutter Clean..." -ForegroundColor Yellow
    Set-Location project
    flutter clean

    Write-Host "[2/4] Resolving dependencies (pub get)..." -ForegroundColor Yellow
    flutter pub get

    Write-Host "[3/4] Compiling optimized Flutter Web release..." -ForegroundColor Yellow
    flutter build web --release --no-wasm-dry-run
    
    Set-Location ..
} catch {
    Write-Host "[ERROR] Pipeline failed during compilation/resolution!" -ForegroundColor Red
    if ((Get-Location).Path.EndsWith("project")) { Set-Location .. }
    Exit 1
}

# ----------------------------------------------------------------------
# 3. Syncing Built Web Assets to Repository Root
# ----------------------------------------------------------------------
Write-Host "[4/4] Syncing compiled assets to repository root..." -ForegroundColor Yellow
try {
    Copy-Item -Recurse -Force project/build/web/* .
    Write-Host "[SUCCESS] Asset synchronization complete!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to copy built assets to root folder!" -ForegroundColor Red
    Exit 1
}

# ----------------------------------------------------------------------
# 4. Stage & Commit using UTF-8 Temporary File
# ----------------------------------------------------------------------
Write-Host "Staging all unified changes in Git..." -ForegroundColor Yellow
git add -A

Write-Host "Creating git commit..." -ForegroundColor Yellow
$tmpFile = Join-Path $PSScriptRoot ".gitcommitmsg.tmp"
try {
    # Force UTF-8 Encoding to perfectly support emojis/Arabic in git commit
    [System.IO.File]::WriteAllText($tmpFile, $commitMessage, [System.Text.Encoding]::UTF8)
    git commit -F $tmpFile
    Write-Host "[SUCCESS] Local commit successful!" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Git commit failed!" -ForegroundColor Red
    if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force }
    Exit 1
} finally {
    if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force }
}

# ----------------------------------------------------------------------
# 5. Push to GitHub Pages Remote Repository
# ----------------------------------------------------------------------
Write-Host "Pushing unified assets to GitHub (speechToText.github.io)..." -ForegroundColor Yellow
try {
    git push origin master
    Write-Host "SUCCESS! Your site is live and your source code is backed up!" -ForegroundColor Green -BackgroundColor DarkGreen
} catch {
    Write-Host "[ERROR] Git push failed! Please check your network and GitHub credentials." -ForegroundColor Red
}
