provider "azurerm" {
    features {}
}

data "azurerm_resource_group" "resourcegroup" {
    name     = "Azure-ResourceGroup"
}

data "azurerm_virtual_network" "virtualnetwork" {
    name                = "Azure-VirtualNetwork"
    resource_group_name = data.azurerm_resource_group.resourcegroup.name
}

data "azurerm_subnet" "subnet" {
    name                 = "Azure-Subnet"
    resource_group_name  = data.azurerm_resource_group.resourcegroup.name
    virtual_network_name = data.azurerm_virtual_network.virtualnetwork.name
}

resource "azurerm_network_interface" "networkinterface" {
    name                = "Azure-NetworkInterface"
    location            = data.azurerm_resource_group.resourcegroup.location
    resource_group_name = data.azurerm_resource_group.resourcegroup.name
    ip_configuration {
        name = "Azure-IP"
        subnet_id = data.azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_windows_virtual_machine" "avm" {
    name = "DS-TERRAFORM"
    resource_group_name = data.azurerm_resource_group.resourcegroup.name
    location = data.azurerm_resource_group.resourcegroup.location
    computer_name = "hostname"
    admin_username = "terraform"
    admin_password = "Password1!"
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

resource "azurerm_virtual_machine_extension" "customize" {
    name                 = "customize"
    virtual_machine_id   = azurerm_windows_virtual_machine.avm.id
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.9"
    protected_settings = <<PROTECTED_SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"./chocolatey.ps1; exit 0;\""
    }
    PROTECTED_SETTINGS

    settings = <<SETTINGS
    {
        "fileUris": [
            "https://gist.githubusercontent.com/mcasperson/c815ac880df481418ff2e199ea1d0a46/raw/5d4fc583b28ecb27807d8ba90ec5f636387b00a3/chocolatey.ps1"
        ]
    }
    SETTINGS
}
