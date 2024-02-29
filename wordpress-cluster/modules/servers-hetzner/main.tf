// ==== NETWORK ==== // 

# Create a Private Network
resource "hcloud_network" "private_net" {
  name     = "private_net"
  ip_range = var.ip_range
}

# Create a Subnet within the Private Network
resource "hcloud_network_subnet" "private_net_subnet" {
  network_id   = hcloud_network.private_net.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.ip_range
}

# Associate Servers with the Private Network's Subnet
resource "hcloud_server_network" "network_connection" {
  count     = var.instances
  server_id = hcloud_server.server[count.index].id
  subnet_id = hcloud_network_subnet.private_net_subnet.id
}


// ==== Certificates ==== //

# Upload a Cert for LoadBalancer (SSL)
resource "hcloud_uploaded_certificate" "wordpress_certificate" {
    name = var.cert_name
    private_key = file("${path.module}/certs/privkey.pem")
    certificate = file("${path.module}/certs/fullchain.pem")
}


// ==== LoadBalancer ==== //

# Make use of existing LB by referencing the name or ID (Hetzner API)

# Reference/Retrieve information about an existing Load Balancer
data "hcloud_load_balancer" "lb_1" {
  name = var.lb_ref_name
}

# Define a Load Balancer target server
resource "hcloud_load_balancer_target" "load_balancer_target" {
  type             = "server"
  load_balancer_id = data.hcloud_load_balancer.lb_1.id
  server_id        = hcloud_server.server[3].id # Index 3 represents the LB host
}

# Define a Load Balancer Service
resource "hcloud_load_balancer_service" "lb_service" {
  load_balancer_id = data.hcloud_load_balancer.lb_1.id
  protocol         = "https"
  listen_port      = "443"  # Source Port
  destination_port = "80" # Destination Port 

  http {
    certificates = [hcloud_uploaded_certificate.wordpress_certificate.id]
 }
}

# Connect the Server's private IPs to the LoadBalancer
resource "hcloud_load_balancer_network" "network_connection" {
  load_balancer_id        = data.hcloud_load_balancer.lb_1.id
  subnet_id               = hcloud_network_subnet.private_net_subnet.id
  enable_public_interface = "true"
}


// ==== Send SSH-Keys to Servers ==== //

# Define an SSH Key to use with the servers
resource "hcloud_ssh_key" "default" {
  name       = "hetzner ssh pub-key"
  public_key = file("~/.ssh/hcloud-key.pub")
}

# Define a secondary SSH Key to use with the servers
resource "hcloud_ssh_key" "senec_key" {
  name       = "hetzner ssh second-key"
  public_key = file("/tmp/second-key.pub")
}


// ==== SERVERS ==== //

# Create Volumes for Servers
resource "hcloud_volume" "server_volume" {
  count    = var.instances
  name     = "web-server-volume-${count.index}"
  size     = var.disk_size
  location = "nbg1"
  format   = "xfs"
}

# Attach and mount Volumes to Servers
resource "hcloud_volume_attachment" "server_vol_attachment" {
  count     = var.instances
  volume_id = hcloud_volume.server_volume[count.index].id
  server_id = hcloud_server.server[count.index].id
  automount = true
}

# Define Server resources
resource "hcloud_server" "server" {
  count       = var.instances
  name        = count.index == 3 ? "LB" : "web${count.index + 1}"
  server_type = "cx21"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = [
    hcloud_ssh_key.default.id,
    hcloud_ssh_key.senec_key.id,
  ]

  # Define the private IP of the Server's
  network {
    network_id = hcloud_network.private_net.id
    ip         = count.index == 3 ? "10.0.0.5" : "10.0.0.${count.index + 6}"
  }

}
