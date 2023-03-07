
# Powershell : SCCM Create a Reboot Reminder

These scripts allow through SCCM compliance rules to display an interface (Notification) in XAML in order to display the number of days since the last restart of the user's computer and to offer to restart it.

![image info](./Screenshots/SampleDisplay.png)

## Scripts Configuration

### Configure the compliance detection script

First, you have to set the max days before showing UI (l16), i setup by default 7 days.

```
$MaxDays = 7
```

If the compliance detection return ``$true``, the remediation script will be executed. (Result not compliant)


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