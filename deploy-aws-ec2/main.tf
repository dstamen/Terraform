provider "vault" {
    address = "http://localhost:8200"
    token = "<unsealtokenfromvault>"
}

data "vault_generic_secret" "aws_auth" {
    path = "secret/<keyname>"
}

provider "aws" {
    region = "us-west-2"
    access_key = data.vault_generic_secret.aws_auth.data["access_key"]
    secret_key = data.vault_generic_secret.aws_auth.data["secret_key"]
}

resource "aws_instance" "example" {
    ami           = "ami-id"
    instance_type = "t2.micro"
    vpc_security_group_ids = ["sg-id","sg-id2","sg-id3"]
    get_password_data = true
    subnet_id = "subnet-id"
    key_name = "<secretkey>"
    tags = {
        Name = "<vmname>"
    }
    user_data = <<EOF
        <powershell>
        net user terraform Password1! /add /y
        net localgroup administrators terraform /add
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name PureStoragePowerShellSDK -Force
        if (((Get-WindowsFeature Multipath-io).InstallState) -like "Available") {
            Set-Service -Name msiscsi -StartupType Automatic
            Start-Service -Name msiscsi
            Set-InitiatorPort -NodeAddress (Get-InitiatorPort).NodeAddress -NewNodeAddress "iqn.1991-05.com.<customiqnname>"
            Add-WindowsFeature -Name 'Multipath-IO' -Restart
        }
        if (((Get-WindowsFeature Multipath-io).InstallState) -like "Installed") {
            if ((Get-IscsiTargetPortal).TargetPortalAddress -notcontains "<ct0-ip-iscsi-target>"){
                New-IscsiTargetPortal -TargetPortalAddress <ct0-ip-iscsi-target>
                Get-IscsiTarget | Connect-IscsiTarget -InitiatorPortalAddress (Get-NetIPAddress |Where-Object {$_.InterfaceAlias -like "Ethernet" -and $_.AddressFamily -like "IPv4"}).IPAddress -IsMultipathEnabled $true -IsPersistent $true -TargetPortalAddress <ct0-ip-iscsi-target>
            }
            if ((Get-IscsiTargetPortal).TargetPortalAddress -notcontains "<ct1-ip-iscsi-target>"){
                New-IscsiTargetPortal -TargetPortalAddress <ct1-ip-iscsi-target>
                Get-IscsiTarget | Connect-IscsiTarget -InitiatorPortalAddress (Get-NetIPAddress |Where-Object {$_.InterfaceAlias -like "Ethernet" -and $_.AddressFamily -like "IPv4"}).IPAddress -IsMultipathEnabled $true -IsPersistent $true -TargetPortalAddress <ct1-ip-iscsi-target>
            }
            if (((Get-MSDSMAutomaticClaimSettings).iSCSI) -ne "True") {
                Enable-MSDSMAutomaticClaim -BusType iSCSI -Confirm:$false
            }
            if (((Get-MSDSMAutomaticClaimSettings).iSCSI) -notcontains "PURE") {
                New-MSDSMSupportedHw -VendorId PURE -ProductId FlashArray
            }
            if (Get-MSDSMGlobalDefaultLoadBalancePolicy -ne "LQD") {
                Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy LQD
            }
            if (((Get-MPIOSetting).CustomPathRecoveryTime) -ne "20") {
                Set-MPIOSetting -NewPathRecoveryInterval 20
            }
            if (((Get-MPIOSetting).UseCustomPathRecoveryTime) -ne "Enabled") {
                Set-MPIOSetting -CustomPathRecovery Enabled
            }
            if (((Get-MPIOSetting).PDORemovePeriod) -ne "30") {
                Set-MPIOSetting -NewPDORemovePeriod 30
            }
            if (((Get-MPIOSetting).DiskTimeoutValue) -ne "60") {
                Set-MPIOSetting -NewDiskTimeout 60
            }
            if (((Get-MPIOSetting).PathVerificationState) -ne "Enabled") {
                Set-MPIOSetting -NewPathVerificationState Enabled
            }
            if ((((Get-Disk).OperationalStatus) -contains "Offline") -and ((((Get-Disk).FriendlyName) -eq "PURE FlashArray"))) {
                Get-Disk | ? {$_.OperationalStatus -eq "Offline"} | Set-Disk -IsOffline $false
            }
            if (((Get-Disk | ? {$_.IsReadOnly -eq "True"}).IsReadOnly) -and ((((Get-Disk).FriendlyName) -eq "PURE FlashArray"))) {
                Get-Disk | ? {$_.IsReadOnly -eq "True"} | Set-Disk -IsReadOnly $false
            }
        }
        </powershell>
        <persist>true</persist>
        EOF
}

output "public_dns" {
    value = ["${aws_instance.example.*.public_dns}"]
}
output "public_ip" {
    value = ["${aws_instance.example.*.public_ip}"]
}
