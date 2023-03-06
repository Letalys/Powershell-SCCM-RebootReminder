<#
.SYNOPSIS
  Create WPF Notification style for remind reboot
.DESCRIPTION
  
.NOTES
  Version:        1.0
  Author:         Letalys
  Creation Date:  06/03/2023
  Purpose/Change: Initial script development
#>

#region Add-Type
[System.Reflection.Assembly]::LoadWithPartialName('PresentationCore')
[System.Reflection.Assembly]::LoadWithPartialName('PresentationFramework')
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
#endregion Add-Type

$MainCode = {
    Param([Parameter(Mandatory=$true)]$XAMLDoc)

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

    #Get the last time reboot
    $DiffTimeSpan = New-TimeSpan $(Get-Date ((Get-CimInstance -Class Win32_OperatingSystem).LastBootUpTime)) $(Get-Date)

    #Get Rounded up day
    $days = [math]::Round($DiffTimeSpan.TotalDays)
    $DaysDigit = $days.ToString().ToCharArray()

    $syncHash.Window.FindName("FormUI").Add_ContentRendered({
        Switch($true){
             ($DaysDigit.length -eq 1){
                 $syncHash.Window.FindName("LBL_DayDigit1").Content = $DaysDigit[0]
                 $syncHash.Window.FindName("LBL_DayDigit2").Content = 0
                 $syncHash.Window.FindName("LBL_DayDigit2").Content = 0
             }
             ($DaysDigit.length -eq 2){
                 $syncHash.Window.FindName("LBL_DayDigit1").Content = $DaysDigit[0]
                 $syncHash.Window.FindName("LBL_DayDigit2").Content = $DaysDigit[1]
                 $syncHash.Window.FindName("LBL_DayDigit2").Content = 0
             }
             ($DaysDigit.length -eq 3){
                 $syncHash.Window.FindName("LBL_DayDigit1").Content = $DaysDigit[0]
                 $syncHash.Window.FindName("LBL_DayDigit2").Content = $DaysDigit[1]
                 $syncHash.Window.FindName("LBL_DayDigit2").Content = $DaysDigit[2]
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
    Write-Output $Days $Global:Selection
}

#Creating runspace
$XAMLUrl = "<Path to your XML Template>"

$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.ApartmentState = "STA"
$Runspace.ThreadOptions = "ReuseThread"
$Runspace.Open()
$Powershell = [powershell]::Create()
$Powershell.AddScript($MainCode)
$Powershell.AddArgument($XAMLUrl)

$Powershell.Runspace = $Runspace
$Results = $Powershell.BeginInvoke()

#Wait Results Completed
while (-not $Results.IsCompleted) {
    Start-Sleep -Milliseconds 100
}

$Results = $Powershell.EndInvoke($Results)

#Close the runspace
$Runspace.Close()
$Runspace.Dispose()

Return $Results
