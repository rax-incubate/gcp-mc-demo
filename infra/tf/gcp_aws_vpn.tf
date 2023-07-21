# GCP side of VPN

locals {
  external_vpn_gateway_interfaces = {
    "0" = {
      tunnel_address        = aws_vpn_connection.env2_env1_vpn01.tunnel1_address
      vgw_inside_address    = aws_vpn_connection.env2_env1_vpn01.tunnel1_vgw_inside_address
      asn                   = aws_vpn_connection.env2_env1_vpn01.tunnel1_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.env2_env1_vpn01.tunnel1_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.env2_env1_vpn01.tunnel1_preshared_key
      vpn_gateway_interface = 0
    },
    "1" = {
      tunnel_address        = aws_vpn_connection.env2_env1_vpn01.tunnel2_address
      vgw_inside_address    = aws_vpn_connection.env2_env1_vpn01.tunnel2_vgw_inside_address
      asn                   = aws_vpn_connection.env2_env1_vpn01.tunnel2_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.env2_env1_vpn01.tunnel2_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.env2_env1_vpn01.tunnel2_preshared_key
      vpn_gateway_interface = 0
    },
    "2" = {
      tunnel_address        = aws_vpn_connection.env2_env1_vpn02.tunnel1_address
      vgw_inside_address    = aws_vpn_connection.env2_env1_vpn02.tunnel1_vgw_inside_address
      asn                   = aws_vpn_connection.env2_env1_vpn02.tunnel1_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.env2_env1_vpn02.tunnel1_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.env2_env1_vpn02.tunnel1_preshared_key
      vpn_gateway_interface = 1
    },
    "3" = {
      tunnel_address        = aws_vpn_connection.env2_env1_vpn02.tunnel2_address
      vgw_inside_address    = aws_vpn_connection.env2_env1_vpn02.tunnel2_vgw_inside_address
      asn                   = aws_vpn_connection.env2_env1_vpn02.tunnel2_bgp_asn
      cgw_inside_address    = "${aws_vpn_connection.env2_env1_vpn02.tunnel2_cgw_inside_address}/30"
      shared_secret         = aws_vpn_connection.env2_env1_vpn02.tunnel2_preshared_key
      vpn_gateway_interface = 1
    }
  }
}

data "google_compute_network" "env1_vpc" {
 project                 = var.env1_gcp_project
  name    = google_compute_network.env1_gcp_vpc.name
}

#Fetch subnetworks
data "google_compute_subnetwork" "env1_subnetworks" {
  project   = var.env1_gcp_project
  count     = length(data.google_compute_network.env1_vpc.subnetworks_self_links)
  self_link = data.google_compute_network.env1_vpc.subnetworks_self_links[count.index]
}

resource "google_compute_ha_vpn_gateway" "env1_vpn_gateway" {
  project = var.env1_gcp_project
  region  = var.env1_gcp_default_region
  name    = "env1-env2"
  network = google_compute_network.env1_gcp_vpc.name
}

resource "google_compute_router" "env1_vpn_router" {
  project     = var.env1_gcp_project
  region      = var.env1_gcp_default_region
  name        = "env1-env2-vpn-router"
  network     = google_compute_network.env1_gcp_vpc.name
  description = "Env1-GCP to Env2-AWS VPN"
  bgp {
    asn            = "65500"
    advertise_mode = "CUSTOM"
    dynamic "advertised_ip_ranges" {
      for_each = data.google_compute_subnetwork.env1_subnetworks
      content {
        range       = advertised_ip_ranges.value.ip_cidr_range
        description = advertised_ip_ranges.value.name
      }
    }
  }
}

resource "google_compute_external_vpn_gateway" "env1_external_gateway" {
  project         = var.env1_gcp_project
  name            =  "env1-env2-external-gw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "Env1-GCP to Env2-AWS VPN"

  dynamic "interface" {
    for_each = local.external_vpn_gateway_interfaces
    content {
      id         = interface.key
      ip_address = interface.value["tunnel_address"]
    }
  }
}

resource "google_compute_vpn_tunnel" "env1_env2_tunnels" {
  for_each                        = local.external_vpn_gateway_interfaces
  provider                        = google-beta
  project                         = var.env1_gcp_project
  region                          = var.env1_gcp_default_region
  labels                          = merge(var.env1_gcp_res_labels)
  name                            = format("aws-gcp-%s", each.key)
  description                     = format("Tunnel to AWS - HA VPN interface %s to AWS interface %s", each.key, each.value.tunnel_address)
  router                          = google_compute_router.env1_vpn_router.self_link
  ike_version                     = 2
  shared_secret                   = each.value.shared_secret
  vpn_gateway                     = google_compute_ha_vpn_gateway.env1_vpn_gateway.self_link
  vpn_gateway_interface           = each.value.vpn_gateway_interface
  peer_external_gateway           = google_compute_external_vpn_gateway.env1_external_gateway.self_link
  peer_external_gateway_interface = each.key
}

resource "google_compute_router_interface" "env1_interfaces" {
  for_each = local.external_vpn_gateway_interfaces
  project  = var.env1_gcp_project
  region   = var.env1_gcp_default_region

  name       = format("aws-gcp-interface%s", each.key)
  router     = google_compute_router.env1_vpn_router.name
  ip_range   = each.value.cgw_inside_address
  vpn_tunnel = google_compute_vpn_tunnel.env1_env2_tunnels[each.key].name
}

resource "google_compute_router_peer" "env1_router_peers" {
  for_each = local.external_vpn_gateway_interfaces
  project  = var.env1_gcp_project
  region   = var.env1_gcp_default_region

  name            = format("aws-gcp-peer%s", each.key)
  router          = google_compute_router.env1_vpn_router.name
  peer_ip_address = each.value.vgw_inside_address
  peer_asn        = each.value.asn
  interface       = google_compute_router_interface.env1_interfaces[each.key].name
}


# AWS side of VPN

resource "aws_customer_gateway" "env2_cgw01" {
  bgp_asn    = "65500" #var.gcp_asn
  ip_address = google_compute_ha_vpn_gateway.env1_vpn_gateway.vpn_interfaces[0].ip_address
  type       = "ipsec.1"

  tags =  var.env2_aws_res_tags
}

resource "aws_customer_gateway" "env2_cgw02" {
  bgp_asn    = "65500" #ßvar.gcp_asn
  ip_address = google_compute_ha_vpn_gateway.env1_vpn_gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"

  tags = var.env2_aws_res_tags
}

resource "aws_vpn_gateway" "env1_vgw01" {
  vpc_id = module.vpc.vpc_id
  tags   = var.env2_aws_res_tags
}

resource "aws_vpn_connection" "env2_env1_vpn01" {
  vpn_gateway_id      = aws_vpn_gateway.env1_vgw01.id
  customer_gateway_id = aws_customer_gateway.env2_cgw01.id
  type                = aws_customer_gateway.env2_cgw01.type
  tags                = var.env2_aws_res_tags
}

resource "aws_vpn_connection" "env2_env1_vpn02" {
  vpn_gateway_id      = aws_vpn_gateway.env1_vgw01.id
  customer_gateway_id = aws_customer_gateway.env2_cgw02.id
  type                = aws_customer_gateway.env2_cgw02.type
  tags                = var.env2_aws_res_tags
}

data "aws_route_tables" "env2_rts" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpn_gateway_route_propagation" "env2_env1" {
  for_each             = toset(data.aws_route_tables.env2_rts.ids)
  vpn_gateway_id       = aws_vpn_gateway.env1_vgw01.id
  route_table_id       = each.value
}