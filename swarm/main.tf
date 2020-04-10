resource "openstack_compute_keypair_v2" "k-app-key" {
  name       = "k-app"
  public_key = file("../j-app.pub")
}

resource "openstack_compute_secgroup_v2" "k-app-sec-group" {
  name        = "k-app-default"
  description = "Security group for k-app."

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 179
    to_port     = 179
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    self        = "true"
  }
  # TCP port 2377 for cluster management communications
  rule {
    from_port   = 2377
    to_port     = 2377
    ip_protocol = "tcp"
    self        = "true"
  }
  # TCP and UDP port 7946 for communication among nodes
  rule {
    from_port   = 7946
    to_port     = 7946
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 7946
    to_port     = 7946
    ip_protocol = "udp"
    self        = "true"
  }
  # UDP port 4789 for overlay network traffic
  rule {
    from_port   = 4789
    to_port     = 4789
    ip_protocol = "udp"
    self        = "true"
  }
  rule {
    from_port   = 30000
    to_port     = 65535
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 30001
    to_port     = 30001
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_instance_v2" "k-app-instance" {
  count           = 4
  name            = format("kapp-%02d", count.index + 1)
  image_name      = "nesc-baseimages-ubuntu-18.04-2020-01-10"
  flavor_name     = "aa.002-0008"
  key_pair        = openstack_compute_keypair_v2.k-app-key.name
  security_groups = [openstack_compute_secgroup_v2.k-app-sec-group.name, "default"]
  network {
    uuid = "abf6e91e-cfa8-4838-9a82-d399adf4af08"
  }
  metadata = {
    nesc-autostart = "yes"
  }
  user_data = file("postscript-swarm.sh")
}

resource "openstack_compute_floatingip_v2" "fip-pool-2" {
  count = 4
  pool  = "datacentre"
}

resource "openstack_compute_floatingip_associate_v2" "fip-associate-2" {
  count       = 4
  floating_ip = element(openstack_compute_floatingip_v2.fip-pool-2.*.address, count.index)
  instance_id = element(openstack_compute_instance_v2.k-app-instance.*.id, count.index)
  fixed_ip    = element(openstack_compute_instance_v2.k-app-instance.*.network.0.fixed_ip_v4, count.index)
}
