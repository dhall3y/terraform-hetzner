resource "hcloud_network" "lan" {
  name     = "private network"
  ip_range = "10.0.1.0/24"
}

resource "hcloud_network_subnet" "lan-subnet" {
  network_id   = hcloud_network.lan.id
  ip_range     = "10.0.1.0/24"
  type         = "cloud"
  network_zone = "eu-central"
}

resource "hcloud_primary_ip" "main" {
  name          = "primary-ip"
  datacenter    = "nbg1-dc3"
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = true
}

resource "hcloud_ssh_key" "main-27042025" {
  name       = "main"
  public_key = file("~/.ssh/main-27042025.pub")
}

resource "hcloud_server" "server" {
  name        = "main"
  server_type = "cx22"
  image       = "rocky-10"
  location    = "nbg1"
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.main.id
  }

  ssh_keys = [hcloud_ssh_key.main-27042025.id]
  network {
    network_id = hcloud_network.lan.id
    alias_ips  = []
  }

  depends_on = [
    hcloud_network_subnet.lan-subnet
  ]
}

output "compute_ip" {
  value = hcloud_server.server.ipv6_address
}
