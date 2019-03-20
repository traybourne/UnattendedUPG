$ini = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\SMTP.ini')

$SENDER    = $ini[0].split("=")[1]
$RECEIVER = $ini[1].split("=")[1]
$USER       = $ini[2].split("=")[1]
$PASS      = $ini[3].split("=")[1]

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.From=*")
    {
        "$_ `"$SENDER`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1')

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.To=*")
    {
        "$_ `"$RECEIVER`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1')

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.Configuration.Fields.Item (`"http://schemas.microsoft.com/cdo/configuration/sendusername`") =*")
    {
        "$_ `"$USER`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1')

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.Configuration.Fields.Item (`"http://schemas.microsoft.com/cdo/configuration/sendpassword`") =*")
    {
        "$_ `"$PASS`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.ps1')