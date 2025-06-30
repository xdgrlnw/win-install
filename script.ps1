Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Window = New-Object system.Windows.Forms.Form
$Window.ClientSize = New-Object System.Drawing.Point(300, 600)
$Window.Text = "Winget Soft Installer by xdgrlnw"
$Window.TopMost = $false

$List = New-Object system.Windows.Forms.GroupBox
$List.Size = New-Object System.Drawing.Size(300, 560)
$List.Text = "Apps list"
$List.Location = [System.Drawing.Point]::Empty

$ScrollPanel = New-Object System.Windows.Forms.Panel
$ScrollPanel.Location = New-Object System.Drawing.Point(10, 20)
$ScrollPanel.Size = New-Object System.Drawing.Size(280, 560)
$ScrollPanel.AutoScroll = $false
$List.Controls.Add($ScrollPanel)

$appList = @(
    ## BROWSERS
    @{Name = "Google Chrome"; ID = "Google.Chrome"},

    ## GAMING
    @{Name = "Discord"; ID = "Discord.Discord"},
    @{Name = "Steam"; ID = "Valve.Steam"},
    @{Name = "Steam Achievment Manager"; ID = "Gibbed.SteamAchievementManager"},
    @{Name = "BattleNet"; ID = "Blizzard.BattleNet"},
    @{Name = "Minecraft Prism Launcher"; ID = "PrismLauncher.PrismLauncher"},
    @{Name = "Minecraft Ely Prism Launcher"; ID = "ElyPrismLauncher.ElyPrismLauncher"},    
    @{Name = "FACEIT"; ID = "FACEITLTD.FACEITClient"},    
    @{Name = "Hydra Launcher"; ID = "HydraLauncher.Hydra"} 

)

$CheckBoxes = @()
$y = 0

foreach ($app in $appList) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $app.Name
    $cb.Tag = $app.ID
    $cb.Width = 300
    $cb.Location = New-Object System.Drawing.Point(0, $y)
    $cb.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
    $CheckBoxes += $cb
    $ScrollPanel.Controls.Add($cb)

    $y += 25

    if (($y + 10) -gt $ScrollPanel.Height -and $ScrollPanel.Height -lt 560) {
        $ScrollPanel.Height = [Math]::Min($ScrollPanel.Height + 25, 560)
    }

    if ($ScrollPanel.Height -ge 560) {
        $ScrollPanel.AutoScroll = $true
    }
}

$Mode = New-Object System.Windows.Forms.CheckBox
$Mode.Text = "Silent Mode"
$Mode.Size = New-Object System.Drawing.Size(120, 40)
$Mode.Location = New-Object System.Drawing.Point(30, 560)
$Mode.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Install = New-Object System.Windows.Forms.Button
$Install.Text = "Install"
$Install.Size = New-Object System.Drawing.Size(150, 40)
$Install.Location = New-Object System.Drawing.Point(150, 560)
$Install.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Window.Controls.AddRange(@($List, $Install, $Mode))

$Install.Add_Click({
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show("Winget not found. Please make sure it is installed.", "Error", "OK", "Error")
        return
    }

    $selectedApps = $CheckBoxes | Where-Object { $_.Checked } | ForEach-Object { $_.Tag }
    if ($selectedApps.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one application.")
        return
    }

    $scriptBlock = {
        param($apps, $silent)
        foreach ($appID in $apps) {
            Write-Host "Installing $appID..."
            $args = @("install", "--id", $appID, "--accept-source-agreements", "--accept-package-agreements")
            if ($silent) { $args += "--silent" }
            & winget @args
        }
        Write-Host "Installation completed."
        Read-Host "Press Enter to exit"
    }

    $encodedArgs = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(
        "& { $($scriptBlock.ToString()) } -apps @('$($selectedApps -join "','")') -silent:$($Mode.Checked.ToString().ToLower())"
    ))

    Start-Process powershell.exe -ArgumentList "-NoExit", "-EncodedCommand", $encodedArgs
})

[void]$Window.ShowDialog()
