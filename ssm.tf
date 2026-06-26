resource "aws_ssm_parameter" "tunneltoken" {
  name  = "${var.prefix}-tunneltoken"
  type  = "SecureString"
  value = data.cloudflare_zero_trust_tunnel_cloudflared_token.tunnel.token
}
