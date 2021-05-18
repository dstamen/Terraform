Connect-VIServer ${first_esx_host_ip} -user root -password '${first_esx_pass}' -Force
Connect-VIServer ${second_esx_host_ip} -user root -password '${second_esx_pass}' -Force
$vmhost1 = Get-VMhost -Name ${first_esx_host_ip}
$vmhost2 = Get-VMhost -Name ${second_esx_host_ip}
Get-VMHostAccount -User root | Set-VMHostAccount -Password "VMware1!" -Confirm:$false
Get-VMHost | Add-VmHostNtpServer -NtpServer "us.pool.ntp.org"
Get-VMHost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService
Get-VMHost | Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "automatic"
$arguments = @{
    rulesetid = 'sshServer'
    enabled = $true
    allowedall = $false
}
$arguments2 = @{
    rulesetid = 'sshServer'
    ipaddress = '192.0.0.0/8'
}
$arguments3 = @{
    rulesetid = 'sshServer'
    ipaddress = '10.0.0.0/8'
}
(get-esxcli -vmhost $vmhost1 -v2).network.firewall.ruleset.set.Invoke($arguments)
(get-esxcli -vmhost $vmhost1 -v2).network.firewall.ruleset.allowedip.add.Invoke($arguments2)
(get-esxcli -vmhost $vmhost1 -v2).network.firewall.ruleset.allowedip.add.Invoke($arguments3)
(get-esxcli -vmhost $vmhost2 -v2).network.firewall.ruleset.set.Invoke($arguments)
(get-esxcli -vmhost $vmhost2 -v2).network.firewall.ruleset.allowedip.add.Invoke($arguments2)
(get-esxcli -vmhost $vmhost2 -v2).network.firewall.ruleset.allowedip.add.Invoke($arguments3)
Get-VirtualSwitch -name vSwitch0 | New-VirtualPortGroup -Name vm -VLanId 1015 -Confirm:$false
Get-VirtualSwitch -name vSwitch0 | New-VirtualPortGroup -Name mgmt -VLanId 1015 -Confirm:$false
Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name iscsi1  -VLanId 1016 -Confirm:$false
Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name iscsi2  -VLanId 1017 -Confirm:$false
Get-VMhost | New-VMHostNetworkAdapter -PortGroup mgmt -VirtualSwitch vSwitch0  -ManagementTrafficEnabled $true -VMotionEnabled $true -Confirm:$false
Get-VMhost | New-VMHostNetworkAdapter -PortGroup iscsi1 -VirtualSwitch vSwitch0 -Confirm:$false
Get-VMhost | New-VMHostNetworkAdapter -PortGroup iscsi2 -VirtualSwitch vSwitch0 -Confirm:$false
Get-VMHost | Get-VMHostNetworkAdapter -Name vmk0 | Set-VMHostNetworkAdapter -ManagementTrafficEnabled $false -Confirm:$false
Get-VirtualPortGroup -Name "VM Network" | Remove-VirtualPortGroup -Confirm:$false
Disconnect-VIServer * -Confirm:$false