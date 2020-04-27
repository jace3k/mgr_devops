resource "openstack_compute_keypair_v2" "l-app-key" {
  name       = "l-app"
  public_key = file("../j-app.pub")
}

resource "openstack_compute_secgroup_v2" "l-app-sec-group" {
  name        = "l-app-default"
  description = "Security group for l-app."

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
  rule {
    from_port   = 6000
    to_port     = 6001
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 7000
    to_port     = 7001
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 8000
    to_port     = 8000
    ip_protocol = "tcp"
    self        = "true"
  }
  rule {
    from_port   = 5432
    to_port     = 5432
    ip_protocol = "tcp"
    self        = "true"
  }
  
  # app
  rule {
    from_port   = 30001
    to_port     = 30001
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_instance_v2" "l-app-instance" {
  count           = 4
  name            = format("lapp-%02d", count.index + 1)
  image_name      = "nesc-baseimages-ubuntu-18.04-2020-01-10"
  flavor_name     = "aa.002-0008"
  key_pair        = openstack_compute_keypair_v2.l-app-key.name
  security_groups = [openstack_compute_secgroup_v2.l-app-sec-group.name, "default"]
  network {
    uuid = "81c3dbd9-f14a-415a-8098-ff857b60831a"
  }
  metadata = {
    nesc-autostart = "yes"
  }
  user_data = file("postscript-raw.sh")
}

resource "openstack_compute_floatingip_v2" "fip-pool-3" {
  count = 4
  pool  = "datacentre"
}

resource "openstack_compute_floatingip_associate_v2" "fip-associate-3" {
  count       = 4
  floating_ip = element(openstack_compute_floatingip_v2.fip-pool-3.*.address, count.index)
  instance_id = element(openstack_compute_instance_v2.l-app-instance.*.id, count.index)
  fixed_ip    = element(openstack_compute_instance_v2.l-app-instance.*.network.0.fixed_ip_v4, count.index)
}


## Test unit

resource "openstack_compute_instance_v2" "l-app-client-instance" {
  name            = "lapp-client"
  image_name      = "nesc-baseimages-ubuntu-18.04-2020-01-10"
  flavor_name     = "aa.002-0008"
  key_pair        = openstack_compute_keypair_v2.l-app-key.name
  security_groups = [openstack_compute_secgroup_v2.l-app-sec-group.name, "default"]
  network {
    uuid = "81c3dbd9-f14a-415a-8098-ff857b60831a"
  }
  metadata = {
    nesc-autostart = "yes"
  }
}

resource "openstack_compute_floatingip_v2" "fip-pool-3-cli" {
  pool = "datacentre"
}

resource "openstack_compute_floatingip_associate_v2" "fip-associate-3-cli" {
  floating_ip = openstack_compute_floatingip_v2.fip-pool-3-cli.address
  instance_id = openstack_compute_instance_v2.l-app-client-instance.id
  fixed_ip    = openstack_compute_instance_v2.l-app-client-instance.network.0.fixed_ip_v4
}
