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

locals {
  syncthing_home = "/var/lib/syncthing/"
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
        "systemctl enable wg-quick@wg0",
        "systemctl start wg-quick@wg0",

        # Syncthing part
        "curl -s https://api.github.com/repos/syncthing/syncthing/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '\"' -f 4 | wget -qi -",
        "tar -xvf syncthing*.tar.gz",
        "mv syncthing*/syncthing /usr/bin",
        "rm -rf syncthing*.tar.gz syncthing*/",

        "mkdir -p ${local.syncthing_home}",
        "chmod 0776 ${local.syncthing_home}",
        "chown root:syncthing ${local.syncthing_home}",

        "systemctl enable syncthing",
        "systemctl start syncthing",
      ],
      timezone = "Europe/Paris",
      packages = [
        "wireguard-tools",
        "tar"
      ]
      users = [
        "default",
        {
          name   = "syncthing"
          system = true
        }
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
        },
        {
          path    = "/etc/systemd/system/syncthing.service",
          content = <<-EOF
            [Unit]
            Description=Syncthing - File Synchronization
            After=network.target

            [Service]
            User=syncthing
            ExecStart=/usr/bin/syncthing --no-browser --no-restart --home=${local.syncthing_home}
            Restart=on-failure
            RestartSec=5

            ProtectSystem=full
            PrivateTmp=true
            SystemCallArchitectures=native
            MemoryDenyWriteExecute=true
            NoNewPrivileges=true

            [Install]
            WantedBy=multi-user.target
          EOF
      }]
    })
  }
}


resource "hcloud_server" "server" {
  name        = "lain"
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
