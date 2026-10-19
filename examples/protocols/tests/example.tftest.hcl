mock_provider "aws" {}

run "protocol_plan" {
  command = plan
  variables {
    client_cidr      = "192.0.2.10/32"
    destination_name = "existing-destination"
    peer_public_key  = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    dtls_psks        = { device = "test-psk" }
  }
}
