$ini = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\SMTP.ini')

$SENDER    = $ini[0].split("=")[1]
$RECEIVER = $ini[1].split("=")[1]
$USER       = $ini[2].split("=")[1]
$PASS      = $ini[3].split("=")[1]

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat') | Foreach {
    if ($_ -like "*ECHO MyEmail.From=*")
    {
        "$_ `"$SENDER`"	>> `"%TEMP%\AlertCountdown.vbs`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat')

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat') | Foreach {
    if ($_ -like "*ECHO MyEmail.To=*")
    {
        "$_ `"$RECEIVER`"	>> `"%TEMP%\AlertCountdown.vbs`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat')

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat') | Foreach {
    if ($_ -like "*ECHO MyEmail.Configuration.Fields.Item (`"http://schemas.microsoft.com/cdo/configuration/sendusername`") =*")
    {
        "$_ `"$USER`"			>> `"%TEMP%\AlertCountdown.vbs`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat')

$newContent = Get-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat') | Foreach {
    if ($_ -like "*ECHO MyEmail.Configuration.Fields.Item (`"http://schemas.microsoft.com/cdo/configuration/sendpassword`") =*")
    {
        "$_ `"$PASS`"			>> `"%TEMP%\AlertCountdown.vbs`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ((Split-Path $MyInvocation.Mycommand.Path) + '\RB_Upgrade.bat')