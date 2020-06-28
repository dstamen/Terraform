# Configure embedded ESXi
provider "vsphere" {
  version        = "1.20.0"
  user           = "administrator@vsphere.local"
  password       = "VMware1!"
  vsphere_server = "192.168.1.3"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "Datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "synology"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = "Cluster/Resources"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "192.168.1.X"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_host" "host" {
  name          = "192.168.1.6"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vmFromLocalOvf" {
  name = "veba.lab.local"
  folder = "terraform"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id = data.vsphere_datastore.datastore.id
  datacenter_id = data.vsphere_datacenter.datacenter.id
  host_system_id = data.vsphere_host.host.id

  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout = 0

  ovf_deploy {
    local_ovf_path = "/Users/dstamen/Downloads/vCenter_Event_Broker_Appliance_v0.4.1.ova"
    disk_provisioning = "thin"
    ip_protocol          = "IPV4"
    ip_allocation_policy = "STATIC_MANUAL"
    ovf_network_map = {
        "VM Network" = data.vsphere_network.network.id
    }
  }

  vapp {
    properties = {
      "guestinfo.hostname" = "veba.lab.local",
      "guestinfo.ipaddress" = "192.168.1.8",
      "guestinfo.netmask" = "24 (255.255.255.0)",
      "guestinfo.gateway" = "VMware123!",
      "guestinfo.dns" = "192.1681.1",
      "guestinfo.domain" = "lab.local",
      "guestinfo.ntp" = "us.pool.ntp.org",
      "guestinfo.http_proxy" = "",
      "guestinfo.https_proxy" = "",
      "guestinfo.proxy_username" = "",
      "guestinfo.proxy_password" = "",
      "guestinfo.no_proxy" = "",
      "guestinfo.root_password" = "VMware1!",
      "guestinfo.enable_ssh" = "True",
      "guestinfo.vcenter_server" = "192.168.1.3",
      "guestinfo.vcenter_username" = "administrator@vsphere.local",
      "guestinfo.vcenter_password" = "VMware1!",
      "guestinfo.vcenter_disable_tls_verification" = "True",
      "guestinfo.event_processor_type" = "OpenFaaS",
      "guestinfo.openfaas_password" = "VMware1!",
      "guestinfo.debug" = "False",
      "guestinfo.docker_network_cidr" = "172.17.0.1/16",
      "guestinfo.pod_network_cidr" = "10.10.0.0/16"
    }
  }
}