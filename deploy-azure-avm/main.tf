provider "azurerm" {
    features {}
}

data "azurerm_resource_group" "resourcegroup" {
    name     = "FSA-team"
}

data "azurerm_virtual_network" "virtualnetwork" {
    name                = "FSA-LAB-USEAST"
    resource_group_name = data.azurerm_resource_group.resourcegroup.name
}

data "azurerm_subnet" "subnet" {
    name                 = "FSA-USEAST1-MGMT"
    resource_group_name  = data.azurerm_resource_group.resourcegroup.name
    virtual_network_name = data.azurerm_virtual_network.virtualnetwork.name
}

resource "azurerm_network_interface" "networkinterface" {
    name                = "DS-TERRAFORM-Interface"
    location            = data.azurerm_resource_group.resourcegroup.location
    resource_group_name = data.azurerm_resource_group.resourcegroup.name
    ip_configuration {
        name = "DS-TERRAFORM-IP"
        subnet_id = data.azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_windows_virtual_machine" "avm" {
    name = "DS-TERRAFORM"
    resource_group_name = data.azurerm_resource_group.resourcegroup.name
    location = data.azurerm_resource_group.resourcegroup.location
    computer_name = "DS-TERRAFORM"
    admin_username = "terraform"
    admin_password = "VMware1!"
    size = "Standard_B1s"
    network_interface_ids = [
        azurerm_network_interface.networkinterface.id,
    ]
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }
}

resource "azurerm_virtual_machine_extension" "configureiscsi" {
    name                 = "configureiscsi"
    virtual_machine_id   = azurerm_windows_virtual_machine.avm.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.9"
    protected_settings = <<PROTECTED_SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"./ConfigureAzureCBS.ps1; exit 0;\""
    }
    PROTECTED_SETTINGS
    settings = <<SETTINGS
    {
        "fileUris": [
            "https://gist.githubusercontent.com/dstamen/e021dcc181c30a9fc5af2d33deafff3f/raw/ae6673e7204df93178956bf7c17641b3be74f6c2/ConfigureAzureCBS.ps1"
        ]
    }
    SETTINGS
}