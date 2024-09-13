# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# data "vsphere_network" "network" {
#   name          = var.network_name
#   datacenter_id = data.vsphere_datacenter.datacenter.id
# }

data "vsphere_virtual_machine" "template" {
  name          = "/${var.datacenter}/vm/${var.almalinux_name}"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm1" {
  name             = "MSP_stateful_test_vm01"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 2
  memory   = 1024

  network_interface {
    # network_id = data.vsphere_network.network.id
    network_id = "network-78"
  }

   clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
 
    customize {
      linux_options {
        host_name = "msp-stateful-test-vm01"
        domain    = "msp.komus.net"
      }
      dns_server_list     = ["10.160.192.5", "10.160.208.5"]
      network_interface {
        ipv4_address = "172.16.1.159"
        ipv4_netmask = 16
      }
 
      ipv4_gateway = "172.16.1.1"
    }
   }

  wait_for_guest_net_timeout = -1
  wait_for_guest_ip_timeout  = -1

  disk {
    label            = "disk0"
    thin_provisioned = true
    size             = 32
  }

  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"
}

output "vm1_ip_address" {
  value = vsphere_virtual_machine.vm1.guest_ip_addresses
}

output "cluster_id" {
  value = data.vsphere_datacenter.datacenter.id
}