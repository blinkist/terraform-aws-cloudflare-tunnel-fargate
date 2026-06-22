resource "random_password" "tunnel_secret" {
  length = 64
}

resource "random_string" "suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.cloudflare_account_id
  name          = local.tunnel_name
  tunnel_secret = base64encode(random_password.tunnel_secret.result)
  # Ingress is managed remotely via cloudflare_zero_trust_tunnel_cloudflared_config below.
  config_src = "cloudflare"
}

moved {
  from = cloudflare_tunnel.tunnel
  to   = cloudflare_zero_trust_tunnel_cloudflared.tunnel
}

# In provider v4 the run token was the computed cloudflare_tunnel.tunnel.tunnel_token
# attribute. v5 no longer exposes it on the resource, so fetch it via this data source.
data "cloudflare_zero_trust_tunnel_cloudflared_token" "tunnel" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "route" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  network    = data.aws_vpc.vpc.cidr_block
  comment    = "Tunnel route for ${var.vpc_id}"
}

moved {
  from = cloudflare_tunnel_route.route
  to   = cloudflare_zero_trust_tunnel_cloudflared_route.route
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "config" {
  count      = var.create_tunnel_config ? 1 : 0
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  # NOTE: provider v5's config schema has no `warp_routing` (only `ingress` and
  # `origin_request`); the v4 module set warp_routing.enabled = true here. This is
  # safe to drop: the API now treats warp-routing as a read-only field that is
  # automatically enabled when the tunnel has a route (created above), and
  # cloudflared has ignored the setting since v2023.10.0. Verified enabled on all
  # live tunnels via the API. WARP clients still also need the device profile's
  # Split Tunnel settings (Zero Trust dashboard) — see the README setup steps.
  config = {
    ingress = [
      for rule in var.ingress_rules : {
        hostname = rule.hostname
        path     = rule.path
        service  = rule.service
      }
    ]
  }
}

moved {
  from = cloudflare_tunnel_config.config
  to   = cloudflare_zero_trust_tunnel_cloudflared_config.config
}
