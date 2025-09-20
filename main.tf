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

resource "hcloud_ssh_key" "main-27042025" {
  name       = "main"
  public_key = file("~/.ssh/main-27042025.pub")
}

# https://cloudinit.readthedocs.io/en/latest/reference/examples_library.html
data "template_cloudinit_config" "cloudinit" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = yamlencode({
      runcmd = [
        # when setting localezone journalctl -u shows the correct time but
        # looking at the log file directly we get the wrong time.
        # to get the right one we need to restart rsyslog
        # https://serverfault.com/questions/506340/timzone-incorrect-for-log-files-only
        "systemctl restart rsyslog",
        "systemct enable wg-quick@wg0",
        "systemctl start wg-quick@wg0",
      ],
      packages = [
        "wireguard-tools"
      ]
      write_files = [
        {
          path = "/etc/wireguard/wg0.conf"
          content = templatefile("${path.root}/templates/wg0.conf.tftpl", {
            endpoint    = var.wg_endpoint
            private_key = var.wg_private_key
            address     = var.wg_address
            port        = var.wg_port
          })
        }
      ]
    })
  }
}


resource "hcloud_server" "server" {
  name        = "main"
  server_type = "cx22"
  image       = "rocky-10"
  location    = "nbg1"
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  ssh_keys = [hcloud_ssh_key.main-27042025.id]
  network {
    network_id = hcloud_network.lan.id
    alias_ips  = []
  }

  user_data = data.template_cloudinit_config.cloudinit.rendered

  depends_on = [
    hcloud_network_subnet.lan-subnet,
  ]
}

resource "hcloud_firewall" "firewall" {
  name = "main firewall"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_firewall_attachment" "fw_ref" {
  firewall_id = hcloud_firewall.firewall.id
  server_ids  = [hcloud_server.server.id]
}

output "compute_ip" {
  value = hcloud_server.server.ipv4_address
}
