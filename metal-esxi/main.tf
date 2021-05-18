terraform {
  required_providers {
    metal = {
      source = "equinix/metal"
      # version = "1.0.0"
    }
  }
}

# Configure the Equinix Metal Provider.
provider "metal" {
  auth_token = var.auth_token
}

# Specify the Equinix Metal Project.
data "metal_project" "project" {
  name = var.project
}

# Create a Equinix Metal Server
resource "metal_device" "esxi_hosts" {
  count            = var.hostcount
  hostname         = format("%s%02d", var.hostname, count.index + 1)
  plan             = var.plan
  metro            = var.metro
  operating_system = var.operating_system
  billing_cycle    = var.billing_cycle
  project_id       = data.metal_project.project.id
}

# Set Network to Hybrid
resource "metal_device_network_type" "esxi_hosts" {
  count     = var.hostcount
  device_id = metal_device.esxi_hosts[count.index].id
  type      = "hybrid"
}

# Add VLAN to Bond
resource "metal_port_vlan_attachment" "management" {
  count     = var.hostcount
  device_id = metal_device_network_type.esxi_hosts[count.index].id
  port_name = "bond0"
  vlan_vnid = "1015"
}

# Add VLAN to Bond
resource "metal_port_vlan_attachment" "iscsi-a" {
  count     = var.hostcount
  device_id = metal_device_network_type.esxi_hosts[count.index].id
  port_name = "bond0"
  vlan_vnid = "1016"
}

# Add VLAN to Bond
resource "metal_port_vlan_attachment" "iscsi-b" {
  count     = var.hostcount
  device_id = metal_device_network_type.esxi_hosts[count.index].id
  port_name = "bond0"
  vlan_vnid = "1017"
}

# Add VLAN to Bond
resource "metal_port_vlan_attachment" "virtualmachine" {
  count     = var.hostcount
  device_id = metal_device_network_type.esxi_hosts[count.index].id
  port_name = "bond0"
  vlan_vnid = "1018"
}
resource "null_resource" "ping1" {
  depends_on = [
    metal_port_vlan_attachment.management,
    metal_device.esxi_hosts,
    metal_port_vlan_attachment.iscsi-a,
    metal_port_vlan_attachment.iscsi-b,
    metal_port_vlan_attachment.virtualmachine
  ]
  provisioner "local-exec" {
      command = "while($ping -notcontains 'True'){$ping = test-connection ${metal_device.esxi_hosts[0].access_private_ipv4} -quiet}"
      interpreter = ["PowerShell", "-Command"]
  }
}

resource "null_resource" "ping2" {
  depends_on = [
    metal_port_vlan_attachment.management,
    metal_device.esxi_hosts,
    metal_port_vlan_attachment.iscsi-a,
    metal_port_vlan_attachment.iscsi-b,
    metal_port_vlan_attachment.virtualmachine
  ]
  provisioner "local-exec" {
      command = "while($ping -notcontains 'True'){$ping = test-connection ${metal_device.esxi_hosts[1].access_private_ipv4} -quiet}"
      interpreter = ["PowerShell", "-Command"]
  }
}

# Sleep to allow servers to come online
resource "null_resource" "sleep" {
  depends_on = [
    metal_port_vlan_attachment.management,
    metal_device.esxi_hosts,
    metal_port_vlan_attachment.iscsi-a,
    metal_port_vlan_attachment.iscsi-b,
    metal_port_vlan_attachment.virtualmachine,
    null_resource.ping1,
    null_resource.ping2
  ]
  provisioner "local-exec" {
      command = "Start-Sleep 30"
      interpreter = ["PowerShell", "-Command"]
  }
}

# Gather Variables for Template
data "template_file" "configure_esxi" {
  depends_on = [
    metal_port_vlan_attachment.management,
    metal_device.esxi_hosts,
    null_resource.sleep
  ]
  template = file("${path.module}/files/configure_esxi.ps1")
  vars = {
    first_esx_pass   = metal_device.esxi_hosts[0].root_password
    first_esx_host_ip   = metal_device.esxi_hosts[0].access_private_ipv4
    second_esx_pass   = metal_device.esxi_hosts[1].root_password
    second_esx_host_ip   = metal_device.esxi_hosts[1].access_private_ipv4
    vcenter_name = var.vcenter_name
  }
}

# Output Rendered Template
resource "local_file" "configure_esxi" {
  depends_on = [
    metal_port_vlan_attachment.management,
    metal_device.esxi_hosts,
    null_resource.sleep
  ]
    content     = data.template_file.configure_esxi.rendered
    filename = "${path.module}/files/rendered-configure_esxi.ps1"
}

#Run Configuration Script
resource "null_resource" "configure_esxi" {
  depends_on = [
    local_file.configure_esxi,
    metal_device.esxi_hosts,
    null_resource.sleep
  ]

  provisioner "local-exec" {
    command = "pwsh ${path.module}/files/rendered-configure_esxi.ps1"
  }
}

# Gather Variables for Template
data "template_file" "vc_template" {
  depends_on = [
    null_resource.configure_esxi,
    metal_device.esxi_hosts,
    null_resource.sleep
  ] 
  template = file("${path.module}/files/deploy_vc.json")
  vars = {
    vcenter_password = var.vcenter_password
    sso_password     = var.vcenter_password
    first_esx_pass   = metal_device.esxi_hosts[0].root_password
    vcenter_network  = var.vcenter_portgroup_name
    first_esx_host   = metal_device.esxi_hosts[0].access_private_ipv4
  }
}

# Output Rendered Template
resource "local_file" "vc_template" {
  depends_on = [
    null_resource.configure_esxi,
    metal_device.esxi_hosts,
    null_resource.sleep
  ]
    content     = data.template_file.vc_template.rendered
    filename = "${path.module}/files/rendered-deploy_vc.json"
}

# Deploy vCenter Server
resource "null_resource" "vc" {
    depends_on = [local_file.vc_template]
  provisioner "local-exec" {
    command = "${var.vc_install_path} install --accept-eula --acknowledge-ceip --no-ssl-certificate-verification ${path.module}/files/rendered-deploy_vc.json"
  }
}

# Outputs
output "hostname" {
    value = metal_device.esxi_hosts[*].hostname
}
output "public_ips" {
    value = metal_device.esxi_hosts[*].access_public_ipv4
}

output "private_ips" {
    value = metal_device.esxi_hosts[*].access_private_ipv4

}