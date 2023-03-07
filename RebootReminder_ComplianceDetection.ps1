<#
.SYNOPSIS
    Create a SCCM Compliance detection method
.DESCRIPTION
    This part need to be used into SCCM compliance detection.
.OUTPUTS
    Boolean : For the compliance result
.NOTES
    Version:        1.0
    Author:         Letalys
    Creation Date:  07/03/2023
    Purpose/Change: Initial script development
#>

#Number of days authorized with no reboot
$MaxDays = 7

#Get the last time reboot (Using this method to be compatible with Powershell 2.0 on Windows 7
if($PSVersionTable.PSVersion -lt [Version]"3.0"){
    $LastBootUpTime = [Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime)
}else{
    $LastBootUpTime = $(Get-Date ((Get-CimInstance -Class Win32_OperatingSystem).LastBootUpTime))
}

$DiffTimeSpan = New-TimeSpan -Start (Get-Date($LastBootUpTime)) -End (Get-Date)
$Days = [math]::Round($DiffTimeSpan.TotalDays)

#Returns are used to boolean value for compliance result :
#if $True = No Compliant, and the remediation script beeing executed. Check the readme.md to get more information
If($Days -ge $MaxDays){
    return $true
}else{
    return $false
}