
# Powershell : SCCM Create a Reboot Reminder

These scripts allow through SCCM compliance rules to display an interface (Notification) in XAML in order to display the number of days since the last restart of the user's computer and to offer to restart it.

![image info](./Screenshots/SampleDisplay.png)

## Scripts Configuration

### Configure the compliance detection script

You can modify the maximum threshold for the number of days between two restarts (Line 16). Beyond this value ,if the number of days since last restart reaches or exceeds this value, then the remediation script will be executed. The value returned by the script will be ``$true`` (considered non-compliant)

```
$MaxDays = 7
```

I setup 7 days by default

### Configure the compliance remediation script

### Configure the XAML UI Logo


## SCCM Compliance rules configuration

### Creating new configuration item

### Creating new baseline configuration

### Deploying



## 🔗 Links
https://github.com/Letalys/Powershell-SCCM-CustomInventory


## Autor
- [@Letalys (GitHUb)](https://www.github.com/Letalys)