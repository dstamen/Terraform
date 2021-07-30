#See https://davidstamen.com/2021/07/30/using-terraform-to-deploy-the-pure-storage-vmware-appliance for more info on using this deployment
#
#vSphere Variables
vc_server = "vc.lab.local"
vc_username = "administrator@vsphere.local"
vc_password = "VMware1!"
vc_datacenter = "Datacenter"
vc_cluster = "cluster"
vc_host = "host1.lab.local" // Needed for OVA/OVF Deployments
vc_datastore = "datastore1"
vc_network = "VM Network"
vc_folder = "MyVMFolder"

#VM Variables
ova_path = "/mnt/c/share/pure-vmware-appliance_3.2.0-prod-signed.ova" #If using \ TF needs Double \\ | https://static.pure1.purestorage.com/vm-analytics-collector/pure-vmware-appliance_3.2.0-prod-signed.ova
vm_name = "pureplugin-tf"
vm_disktype = "thin" #thin, flat, thick, sameAsSource
vm_dhcp = "False" # True or False. If true comment out lines 62-67 in main.tf
vm_ip = "10.21.234.27"
vm_netmask = "255.255.255.0"
vm_gateway = "10.21.234.1"
vm_dns1 = "10.21.234.10"
vm_dns2 = "10.21.234.11"
vm_hostname = "pureplugin.lab.local"
vm_appliancetype = "vSphere Remote Client Plugin" #M Analytics Collector","vSphere Remote Client Plugin", "None (Offline Installation