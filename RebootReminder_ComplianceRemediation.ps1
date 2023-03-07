<#
.SYNOPSIS
    Create WPF Notification style for remind reboot
.DESCRIPTION
    This part need to be used into SCCM compliance remediation.
.NOTES
    Version:        1.0
    Author:         Letalys
    Creation Date:  07/03/2023
    Purpose/Change: Initial script development
#>

#region Add-Type
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')
[System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
#endregion Add-Type

$RunspaceCode = {
    Param(
        [Parameter(Mandatory=$true)]$XAMLDoc,
        [Parameter(Mandatory=$true)]$LastRebootDays,
        [Parameter(Mandatory=$true)]$ErrorLog
    )

    try{
        [xml]$XAML = [IO.File]::ReadAllText($XAMLDoc,[Text.Encoding]::GetEncoding(65001))

        #Creation of a Thread-Safe synchronization HashTable, allows to retrieve objects and properties by any RunSpace (Execution space)
        $syncHash = [hashtable]::Synchronized(@{})

        #Load XAML and Add to Hashtable
        $XAMLReader=(New-Object System.Xml.XmlNodeReader $XAML)
        $syncHash.Window=[Windows.Markup.XamlReader]::Load($XAMLReader)

        #Calculate WPF Window position at bottom right
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $syncHash.Window.Left = $screen.Right - $syncHash.Window.Width
        $syncHash.Window.Top = $screen.Bottom - $syncHash.Window.Height

        #Set topmost
        $syncHash.Window.TopMost = $true
        $DaysDigit = $LastRebootDays.ToString().ToCharArray()

        $syncHash.Window.FindName("FormUI").Add_ContentRendered({
            $syncHash.Window.FindName("LBL_ComputerName").Content = $env:COMPUTERNAME
            Switch($true){
                ($DaysDigit.length -eq 1){
                    $syncHash.Window.FindName("LBL_DayDigit1").Content = $DaysDigit[0]
                    $syncHash.Window.FindName("LBL_DayDigit2").Content = 0
                    $syncHash.Window.FindName("LBL_DayDigit3").Content = 0
                }
                ($DaysDigit.length -eq 2){
                    $syncHash.Window.FindName("LBL_DayDigit1").Content = $DaysDigit[0]
                    $syncHash.Window.FindName("LBL_DayDigit2").Content = $DaysDigit[1]
                    $syncHash.Window.FindName("LBL_DayDigit3").Content = 0
                }
                ($DaysDigit.length -eq 3){
                    $syncHash.Window.FindName("LBL_DayDigit1").Content = $DaysDigit[0]
                    $syncHash.Window.FindName("LBL_DayDigit2").Content = $DaysDigit[1]
                    $syncHash.Window.FindName("LBL_DayDigit3").Content = $DaysDigit[2]
                }
            }
        })

        $Global:Selection = $null
        $syncHash.Window.FindName("B_RebootNow").Add_Click({
            $Global:Selection = 1
            $syncHash.Window.close()
        })

        $syncHash.Window.FindName("B_RebootLater").Add_Click({
            $Global:Selection = 2
            $syncHash.Window.close()
        })

        #Show Window
        $syncHash.Window.ShowDialog() | Out-Null
        Write-Output "$($Global:Selection)"
    }catch{
        Write-Output "Error in line $($_.InvocationInfo.ScriptLineNumber) : $($_)" | Out-File $ErrorLog
    }
}

#Creating runspace
$XAMLUrl = "$PSScriptRoot\UI\RebootReminder.UI.xml"
$ErrLogUI = "$PSScriptRoot\CCM-RebootReminder-Runspace.log"
$ErrLogExec = "$PSScriptRoot\CCM-RebootReminder-MainExec.log"

Try{
    #Get the last time reboot (Using this method to be compatible with Powershell 2.0 on Windows 7)
    if($PSVersionTable.PSVersion -lt [Version]"4.0"){
        $LastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime)
    }else{
        $LastBootUpTime = $(Get-Date ((Get-CimInstance -Class Win32_OperatingSystem).LastBootUpTime))
    }

    $DiffTimeSpan = New-TimeSpan -Start (Get-Date($LastBootUpTime)) -End (Get-Date)
    $Days = [math]::Round($DiffTimeSpan.TotalDays)
    
    $Runspace = [runspacefactory]::CreateRunspace()
    $Runspace.ApartmentState = "STA"
    $Runspace.ThreadOptions = "ReuseThread"
    $Runspace.Open()

    $Powershell = [powershell]::Create()
    $Powershell.AddScript($RunspaceCode)
    $Powershell.AddArgument($XAMLUrl)
    $Powershell.AddArgument($Days)
    $Powershell.AddArgument($ErrLogUI)

    $Powershell.Runspace = $Runspace
    $Results = $Powershell.BeginInvoke()

    #Wait Results Completed
    while (-not $Results.IsCompleted) {
        Start-Sleep -Seconds 1
    }

    $Results = $Powershell.EndInvoke($Results)

    #Close the runspace
    $Runspace.Close()
    $Runspace.Dispose()

    #Restart Computer
    if ([int]$Results[0] -eq 1){
        Restart-Computer -Force
    }
}Catch{
	Write-Output "Error in line $($_.InvocationInfo.ScriptLineNumber) : $($_)" | Out-File $ErrLogExec
}