terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscriptionID
  tenant_id       = var.tenantID
}


resource "azurerm_resource_group" "dev-rg" {
  name     = "eastus2-dev-rg"
  location = "East US"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "dev-vnet" {
  name                = "eastus2-dev-vnet"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  address_space       = ["10.123.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "dev-subnet1" {
  name                 = "eastus2-dev-subnet1"
  resource_group_name  = azurerm_resource_group.dev-rg.name
  virtual_network_name = azurerm_virtual_network.dev-vnet.name
  address_prefixes     = ["10.123.0.0/24"]
}

resource "azurerm_network_security_group" "dev-subnet1-nsg" {
  name                = "eastus2-dev-subnet1-nsg1"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet_network_security_group_association" "dev-subnet1-nsg-association" {
  subnet_id                 = azurerm_subnet.dev-subnet1.id
  network_security_group_id = azurerm_network_security_group.dev-subnet1-nsg.id
}

resource "azurerm_public_ip" "dev-pip1" {
  name                = "eastus2-dev-pip1"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "dev-nic1" {
  name                = "eastus2-dev-nic1"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev-subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev-pip1.id
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_linux_virtual_machine" "dev-linux-vm1" {
  name                = "eastus2-dev-linux-vm1"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  size                = "Standard_F2"
  admin_username      = "vshinde"
  network_interface_ids = [
    azurerm_network_interface.dev-nic1.id
  ]

  custom_data = filebase64("customdata.tpl")

  admin_ssh_key {
    username   = "vshinde"
    public_key = file("~/.ssh/azure_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-host-add.tpl", {
      hostname     = self.public_ip_address
      username     = "vshinde"
      identityfile = "~/.ssh/azure_key"
    })

    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }

  tags = {
    environment = "dev"
  }
}

data "azurerm_public_ip" "dev-pip1-data" {
  name                = azurerm_public_ip.dev-pip1.name
  resource_group_name = azurerm_resource_group.dev-rg.name
}

output "PublicIP" {
  value       = "${azurerm_linux_virtual_machine.dev-linux-vm1.name}: ${data.azurerm_public_ip.dev-pip1-data.ip_address}"
  sensitive   = false
  description = "description"
  depends_on  = []
}
