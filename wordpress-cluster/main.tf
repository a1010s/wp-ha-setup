terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.42.0"
    }
  }
}


# Input your API Token in variables.tf (main TF dir)
provider "hcloud" {
    token = var.hcloud_token
}

module "wp-cluster-servers" {
    source      = "./modules/servers-hetzner"
}
