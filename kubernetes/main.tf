resource "openstack_compute_keypair_v2" "j-app-key" {
  name       = "j-app"
  public_key = file("../j-app.pub")
}

resource "openstack_compute_secgroup_v2" "j-app-sec-group" {
  name        = "j-app-default"
  description = "Security group for j-app."

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
  rule {
    from_port   = 6443
    to_port     = 6443
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 2379
    to_port     = 2380
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 10250
    to_port     = 10252
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 30000
    to_port     = 65535
    ip_protocol = "tcp"
    self        = "true"
  }
  # Flannel
  rule {
    from_port   = 8285
    to_port     = 8285
    ip_protocol = "udp"
    self        = "true"
  }
  rule {
    from_port   = 8472
    to_port     = 8472
    ip_protocol = "udp"
    self        = "true"
  }
  # app
  rule {
    from_port   = 30001
    to_port     = 30001
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  # app 2
  rule {
    from_port   = 30002
    to_port     = 30002
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  # db
  rule {
    from_port   = 30003
    to_port     = 30003
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_instance_v2" "j-app-instance" {
  count           = 4
  name            = format("japp-%02d", count.index + 1)
  image_name      = "nesc-baseimages-ubuntu-18.04-2020-01-10"
  flavor_name     = "aa.002-0008"
  key_pair        = openstack_compute_keypair_v2.j-app-key.name
  security_groups = [openstack_compute_secgroup_v2.j-app-sec-group.name, "default"]
  network {
    uuid = "373db6d2-63a6-4344-bca8-688fb2c45f76"
  }
  metadata = {
    nesc-autostart = "yes"
  }
  user_data = file("postscript.sh")
}

resource "openstack_compute_floatingip_v2" "fip-pool" {
  count = 4
  pool  = "datacentre"
}

resource "openstack_compute_floatingip_associate_v2" "fip-associate" {
  count       = 4
  floating_ip = element(openstack_compute_floatingip_v2.fip-pool.*.address, count.index)
  instance_id = element(openstack_compute_instance_v2.j-app-instance.*.id, count.index)
  fixed_ip    = element(openstack_compute_instance_v2.j-app-instance.*.network.0.fixed_ip_v4, count.index)
}


## Test unit

resource "openstack_compute_instance_v2" "j-app-client-instance" {
  name            = "japp-client"
  image_name      = "nesc-baseimages-ubuntu-18.04-2020-01-10"
  flavor_name     = "aa.002-0008"
  key_pair        = openstack_compute_keypair_v2.j-app-key.name
  security_groups = [openstack_compute_secgroup_v2.j-app-sec-group.name, "default"]
  network {
    uuid = "373db6d2-63a6-4344-bca8-688fb2c45f76"
  }
  metadata = {
    nesc-autostart = "yes"
  }
}

resource "openstack_compute_floatingip_v2" "fip-pool-cli" {
  pool = "datacentre"
}

resource "openstack_compute_floatingip_associate_v2" "fip-associate-cli" {
  floating_ip = openstack_compute_floatingip_v2.fip-pool-cli.address
  instance_id = openstack_compute_instance_v2.j-app-client-instance.id
  fixed_ip    = openstack_compute_instance_v2.j-app-client-instance.network.0.fixed_ip_v4
}
