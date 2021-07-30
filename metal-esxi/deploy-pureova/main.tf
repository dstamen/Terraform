# Configure embedded ESXi
provider "vsphere" {
  version        = "~> 1.20.0"
  user           = var.vc_username
  password       = var.vc_password
  vsphere_server = var.vc_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = var.vc_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vc_datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = format("%s%s", var.vc_cluster, "/Resources")
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.vc_network
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = var.vc_host
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "deploy_ova" {
  name = var.vm_name
  folder = var.vc_folder
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id = data.vsphere_datastore.datastore.id
  datacenter_id = data.vsphere_datacenter.datacenter.id
  host_system_id = data.vsphere_host.host.id

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout = 0

  ovf_deploy {
    local_ovf_path = var.ova_path // Comment out if using Remote
    //remote_ovf_url = var.ova_path //Comment out if using Local
    disk_provisioning = var.vm_disktype
    ip_protocol          = "IPV4"
    ip_allocation_policy = "STATIC_MANUAL"
    ovf_network_map = {
      "VM Network" = data.vsphere_network.network.id
    }
  }

  vapp {
    properties = {
      "Appliance_Type" = var.vm_appliancetype
      "DHCP" = var.vm_dhcp,
      "IP_Address" = var.vm_ip, //comment out if DHCP is True
      "Netmask" = var.vm_netmask, //comment out if DHCP is True
      "Gateway" = var.vm_gateway, //comment out if DHCP is True
      "DNS_Server_1" = var.vm_dns1, //comment out if DHCP is True
      "DNS_Server_2" = var.vm_dns1, //comment out if DHCP is True
      "Hostname"  = var.vm_hostname //comment out if DHCP is True
    }
  }
}
