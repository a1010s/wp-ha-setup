variable "instances" {
  default = "4"
}

variable "disk_size" {
  default = "20"
} 


variable "ip_range" {
  default = "10.0.0.0/24"
}

variable "location" {
  default = "nbg1"
}

variable "cert_name" {
  default = "wordpress-as.senecops.com"
}

variable "lb_ref_name" {
  description = "Name of the LB from Hetzner Cloud Console"
  default = "load-balancer-1"
}