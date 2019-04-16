$CurDir = (Split-Path $MyInvocation.Mycommand.Path)
Function MsgBox($Message, $Type, $Title)
{
   [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
   [Microsoft.VisualBasic.Interaction]::MsgBox($Message, "SystemModal, $Type", $Title)
}

if (!(Test-Path "$CurDir\SMTP.ini")) {
$ini = MsgBox "SMTP.ini not found! Email alerts will not function without this. `nDo you want to continue?" "YesNo" "UnattendedUPG Build"
switch ($ini) {
    "No" { Exit 1 }
	"Yes" { Exit 0 }
}}

$ini = Get-Content ($CurDir + '\SMTP.ini')

$SENDER    = $ini[0].split("=")[1]
$RECEIVER = $ini[1].split("=")[1]
$USER       = $ini[2].split("=")[1]
$PASS      = $ini[3].split("=")[1]

$newContent = Get-Content ($CurDir + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.From=*")
    {
        "$_ `"$SENDER`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ($CurDir + '\RB_Upgrade.ps1')

$newContent = Get-Content ($CurDir + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.To=*")
    {
        "$_ `"$RECEIVER`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ($CurDir + '\RB_Upgrade.ps1')

$newContent = Get-Content ($CurDir + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.Configuration.Fields.Item (`"http://schemas.microsoft.com/cdo/configuration/sendusername`") =*")
    {
        "$_ `"$USER`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ($CurDir + '\RB_Upgrade.ps1')

$newContent = Get-Content ($CurDir + '\RB_Upgrade.ps1') | Foreach {
    if ($_ -like "*MyEmail.Configuration.Fields.Item (`"http://schemas.microsoft.com/cdo/configuration/sendpassword`") =*")
    {
        "$_ `"$PASS`""
    }
    else
    {
        $_
    }
} 
$newContent | Set-Content ($CurDir + '\RB_Upgrade.ps1')