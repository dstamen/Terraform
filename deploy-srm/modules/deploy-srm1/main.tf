provider "vsphere" {
  version        = "1.20.0"
  user           = "administrator@vsphere.local"
  password       = "VMware123!"
  vsphere_server = "vc01.lab.local"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "Datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "mydatastore"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = "mycluster/Resources"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "mynetwork"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = "myesxihost.lab.local"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vmFromLocalOvf" {
  name = "srm1.lab.local"
  folder = "myVMFolder"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id = data.vsphere_datastore.datastore.id
  datacenter_id = data.vsphere_datacenter.datacenter.id
  host_system_id = data.vsphere_host.host.id

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout = 0

  ovf_deploy {
    local_ovf_path = "/mnt/c/share/VMware/SRM/VMware-srm-va-8.3.0.4272-16168265/bin/srm-va_OVF10.ovf"
    disk_provisioning = "thin"
    ip_protocol          = "IPV4"
    ip_allocation_policy = "STATIC_MANUAL"
    ovf_network_map = {
        "Network 1" = data.vsphere_network.network.id
    }
  }

  vapp {
    properties = {
      "varoot-password" = "VMware123!",
      "vaadmin-password" = "VMware123!",
      "dbpassword" = "VMware123!",
      "ntpserver" = "us.pool.ntp.org",
      "enable_sshd" = "True",
      "vami.hostname" = "srm1.lab.local",
      "addrfamily" = "ipv4",
      "netmode"  = "static",
      "gateway"  = "192.168.1.1",
      "domain"  = "lab.local",
      "searchpath" = "fsa.lab",
      "DNS" = "192.168.1.1",
      "ip0" = "192.168.1.5",
      "netprefix0" = "24"
    }
  }
}