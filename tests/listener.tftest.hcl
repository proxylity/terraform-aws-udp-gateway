mock_provider "aws" {
  mock_resource "aws_cloudformation_stack" {
    defaults = {
      outputs = {
        ListenerName          = "listener-123"
        Port                  = "12345"
        Domain                = "example"
        DestinationNames      = "processor,storage"
        WireGuardPublicKey    = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        DtlsServerCertificate = "certificate"
        WebRtcFingerprint     = "AA:BB"
        WebRtcSctpPort        = "5000"
        WebRtcChannelId       = "0"
        WebRtcSignalingMode   = "public"
        WebRtcSignalingToken  = "test-token"
        WebRtcSignalingUrl    = "https://example.invalid/signaling"
      }
    }
  }
}

variables {
  stack_name = "test-listener"
}

run "safe_defaults_and_output_types" {
  command = apply

  assert {
    condition     = jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.ClientRestrictions == { Networks = [], Domains = [] }
    error_message = "Default restrictions must not admit traffic."
  }
  assert {
    condition     = output.port == 12345 && output.endpoint == "example.proxylity.com:12345" && output.hostname == "example.proxylity.com"
    error_message = "Port must be numeric and endpoints must include the DNS suffix."
  }
  assert {
    condition     = output.destination_names == tolist(["processor", "storage"])
    error_message = "Destination names must be a list."
  }
  assert {
    condition     = output.wireguard_public_key == null && output.dtls_server_certificate == null && output.webrtc == null && output.webrtc_signaling_token == null
    error_message = "UDP must not expose protocol-specific attributes."
  }
  assert {
    condition     = toset(keys(jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Outputs)) == toset(["ListenerName", "Port", "Domain", "DestinationNames"])
    error_message = "Do not request GetAtt attributes that UDP does not return."
  }
  assert {
    condition = (
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Mappings.ProxylityConfig["Fn::Transform"].Parameters.Location["Fn::Sub"] == "s3://proxylity-config-$${AWS::Region}/$${AWS::AccountId}/customer-config.json" &&
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.ServiceToken["Fn::FindInMap"][2] == "ServiceToken"
    )
    error_message = "Account configuration must remain resolved by CloudFormation, not Terraform."
  }
}

run "inline_destination_wire_contract" {
  command = plan
  variables {
    listener_name       = "Example listener"
    description         = "Test listener"
    client_restrictions = { networks = ["192.0.2.0/24", "2001:db8::/32"] }
    metrics_enabled     = true
    log_group_name      = "/proxylity/listener"
    role                = { arn = "arn:aws:iam::123456789012:role/observer", duration = "1:00:00" }
    tags                = { Project = "test" }
    destinations = {
      processor = {
        destination_arn   = "arn:aws:lambda:us-east-1:123456789012:function:processor"
        role              = { arn = "arn:aws:iam::123456789012:role/delivery", duration = "0:30:00" }
        batching          = { count = 10, timeout_in_seconds = 0.25, size_in_mb = 1.5 }
        filter_expression = "0x01"
        formatter         = "coap"
        metrics_enabled   = false
        arguments         = { tenant_id = "tenant", use_async_invoke = false, use_response_streaming = true }
      }
      storage = {
        destination_arns = { "*" = "arn:aws:s3:::fallback", "us-east-1" = "arn:aws:s3:::regional" }
      }
      unbound = {}
    }
    destination_names = ["existing-destination"]
  }
  assert {
    condition = (
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Name == "Example listener" &&
      !contains(keys(jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties), "ListenerName")
    )
    error_message = "The display name wire key must be Name, not ListenerName."
  }
  assert {
    condition = jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations[0] == {
      Name             = "processor"
      DestinationArn   = "arn:aws:lambda:us-east-1:123456789012:function:processor"
      Role             = { Arn = "arn:aws:iam::123456789012:role/delivery", Duration = "0:30:00" }
      Batching         = { Count = 10, TimeoutInSeconds = 0.25, SizeInMB = 1.5 }
      FilterExpression = "0x01"
      Formatter        = "coap"
      MetricsEnabled   = false
      Arguments        = { TenantId = "tenant", UseAsyncInvoke = false, UseResponseStreaming = true }
    }
    error_message = "Destination types, false values, SizeInMB and argument casing must survive serialization; absent fields must be omitted."
  }
  assert {
    condition = (
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations[1].DestinationArn["*"] == "arn:aws:s3:::fallback" &&
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations[2].DestinationArn == {} &&
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations[3] == "existing-destination"
    )
    error_message = "Regional, unbound and referenced destinations must preserve the service contract."
  }
}

run "protocol_aware_formatters" {
  command = plan
  variables {
    destinations = {
      coap-plus = { formatter = "coap+" }
      syslog    = { formatter = "syslog" }
    }
  }
  assert {
    condition = (
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations[0].Formatter == "coap+" &&
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations[1].Formatter == "syslog"
    )
    error_message = "The coap+ and syslog formatters must pass validation and be serialized to CloudFormation."
  }
}

run "wireguard" {
  command = apply
  variables {
    protocol = "wg"
    wireguard = {
      allow_unknown_peers         = true
      unknown_peer_pre_shared_key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
      decapsulated_delivery       = false
      key_refresh_token           = "rotation-1"
      peers = [{
        public_key    = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        shared_secret = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        allowed_ips   = ["10.0.0.1/32"]
      }]
    }
  }
  assert {
    condition = (
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Peers[0].AllowedIPs[0] == "10.0.0.1/32" &&
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.DecapsulatedDelivery == false &&
      output.wireguard_public_key == "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    )
    error_message = "WireGuard settings and public key must be wired."
  }
}

run "all_destination_arguments" {
  command = plan
  variables {
    destinations = {
      iot = {
        arguments = {
          dynamic_topic_suffix    = true
          topic_suffix_expression = "[0:4]"
          topic_suffix_formatter  = "hex"
        }
      }
      kinesis = {
        arguments = {
          partition_key_expression           = "[0:4]"
          partition_key_expression_formatter = "ascii"
        }
      }
      lambda = {
        arguments = {
          tenant_id_expression = "[0:4]"
          tenant_id_formatter  = "utf8"
          use_async_invoke     = true
        }
      }
      location = {
        arguments = {
          device_id_expression          = "[0:4]"
          latitude_expression           = "[4:8]"
          longitude_expression          = "[8:12]"
          scale_factor                  = 0.000001
          accuracy_expression           = "[12:16]"
          position_property_expressions = { source = "[16:20]" }
          timestamp_expression          = "[20:24]"
          timestamp_time_unit           = "milliseconds"
        }
      }
      sqs = {
        arguments = {
          send_raw                            = true
          use_message_attributes              = false
          message_group_id_expression         = "[0:4]"
          message_group_id_formatter          = "base64"
          message_deduplication_id_expression = "[4:8]"
          message_deduplication_id_formatter  = "hex"
        }
      }
    }
  }
  assert {
    condition = [for dest in jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations : dest.Arguments] == [
      { DynamicTopicSuffix = true, TopicSuffixExpression = "[0:4]", TopicSuffixFormatter = "hex" },
      { PartitionKeyExpression = "[0:4]", PartitionKeyExpressionFormatter = "ascii" },
      { TenantIdExpression = "[0:4]", TenantIdFormatter = "utf8", UseAsyncInvoke = true },
      {
        DeviceIdExpression  = "[0:4]", LatitudeExpression = "[4:8]", LongitudeExpression = "[8:12]",
        ScaleFactor         = 0.000001, AccuracyExpression = "[12:16]", PositionPropertyExpressions = { source = "[16:20]" },
        TimestampExpression = "[20:24]", TimestampTimeUnit = "milliseconds"
      },
      {
        SendRaw                 = true, UseMessageAttributes = false, MessageGroupIdExpression = "[0:4]",
        MessageGroupIdFormatter = "base64", MessageDeduplicationIdExpression = "[4:8]", MessageDeduplicationIdFormatter = "hex"
      }
    ]
    error_message = "All service argument names and nested values must match the current custom-resource contract."
  }
}

run "lambda_microvm_arguments" {
  command = plan
  variables {
    destinations = {
      microvm = {
        destination_arn = "arn:aws:lambda:us-east-1:123456789012:microvm-image:echo"
        arguments = {
          idle_duration_seconds             = 900
          execution_role_arn                = "arn:aws:iam::123456789012:role/microvm-runtime"
          run_hook_extra_data               = "{\"Example\":\"lambda-microvm\"}"
          egress_network_connector_arns     = ["arn:aws:lambda:us-east-1:123456789012:network-connector:nc-abc123"]
          runtime_log_group_name            = "/my-app/microvms"
          use_tenant_id_for_log_stream_name = true
          tenant_id_expression              = "u8[0] >> 6 ?? 0"
          tenant_id_formatter               = "hex"
        }
      }
    }
  }
  assert {
    condition = jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Destinations[0].Arguments == {
      IdleDurationSeconds         = 900
      ExecutionRoleArn            = "arn:aws:iam::123456789012:role/microvm-runtime"
      RunHookExtraData            = "{\"Example\":\"lambda-microvm\"}"
      EgressNetworkConnectorArns  = ["arn:aws:lambda:us-east-1:123456789012:network-connector:nc-abc123"]
      RuntimeLogGroupName         = "/my-app/microvms"
      UseTenantIdForLogStreamName = true
      TenantIdExpression          = "u8[0] >> 6 ?? 0"
      TenantIdFormatter           = "hex"
    }
    error_message = "MicroVM argument names and values must match the custom-resource contract."
  }
}

run "invalid_microvm_with_lambda_invoke_modes" {
  command = plan
  variables {
    destinations = {
      invalid = {
        destination_arn = "arn:aws:lambda:us-east-1:123456789012:microvm-image:echo"
        arguments       = { use_async_invoke = true }
      }
    }
  }
  expect_failures = [var.destinations]
}

run "invalid_microvm_idle_duration" {
  command = plan
  variables { destinations = { invalid = { arguments = { idle_duration_seconds = 90.5 } } } }
  expect_failures = [var.destinations]
}

run "invalid_microvm_egress_connectors" {
  command = plan
  variables { destinations = { invalid = { arguments = { egress_network_connector_arns = ["arn:aws:lambda:us-east-1:123456789012:microvm-image:echo"] } } } }
  expect_failures = [var.destinations]
}

run "invalid_microvm_empty_egress_connectors" {
  command = plan
  variables { destinations = { invalid = { arguments = { egress_network_connector_arns = [] } } } }
  expect_failures = [var.destinations]
}

run "invalid_microvm_execution_role" {
  command = plan
  variables { destinations = { invalid = { arguments = { execution_role_arn = "not-a-role" } } } }
  expect_failures = [var.destinations]
}

run "dtls" {
  command = apply
  variables {
    protocol = "dtls"
    dtls = {
      psks                      = { device = "test-psk" }
      server_secret             = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
      require_cookies           = true
      allow_early_data          = false
      early_data_window_seconds = 604800
      cert_refresh_token        = "rotation-1"
    }
  }
  assert {
    condition = (
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.Psks.device == "test-psk" &&
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.EarlyDataWindowSeconds == 604800 &&
      output.dtls_server_certificate == "certificate"
    )
    error_message = "DTLS settings and certificate must be wired."
  }
}

run "webrtc_public" {
  command = apply
  variables {
    protocol = "webrtc"
    webrtc = {
      signaling_mode          = "public"
      signaling_refresh_token = "rotation-1"
      require_cookies         = true
      server_secret           = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
      cert_refresh_token      = "rotation-1"
    }
  }
  assert {
    condition = (
      output.webrtc.sctp_port == 5000 && output.webrtc.channel_id == 0 &&
      output.webrtc_signaling_token == "test-token" &&
      jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Resources.ProxylityListener.Properties.WebRtcSignalingRefreshToken == "rotation-1"
    )
    error_message = "Public WebRTC connection metadata and rotation settings must be wired."
  }
}

run "webrtc_private" {
  command = plan
  variables {
    protocol = "webrtc"
  }
  assert {
    condition = (
      !contains(keys(jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Outputs), "WebRtcSignalingToken") &&
      !contains(keys(jsondecode(aws_cloudformation_stack.proxylity_listener.template_body).Outputs), "WebRtcSignalingUrl")
    )
    error_message = "Default WebRTC must not request public signaling attributes."
  }
}

run "invalid_protocol" {
  command = plan
  variables { protocol = "tcp" }
  expect_failures = [var.protocol]
}

run "invalid_cross_protocol" {
  command = plan
  variables { wireguard = {} }
  expect_failures = [var.wireguard]
}

run "invalid_early_data_window" {
  command = plan
  variables {
    protocol = "dtls"
    dtls     = { early_data_window_seconds = 604801 }
  }
  expect_failures = [var.dtls]
}

run "invalid_fractional_window" {
  command = plan
  variables {
    protocol = "dtls"
    dtls     = { early_data_window_seconds = 1.5 }
  }
  expect_failures = [var.dtls]
}

run "invalid_webrtc_cookies" {
  command = plan
  variables {
    protocol = "webrtc"
    webrtc   = { require_cookies = false }
  }
  expect_failures = [var.webrtc]
}

run "invalid_arn_forms" {
  command = plan
  variables {
    destinations = { invalid = { destination_arn = "arn:aws:s3:::one", destination_arns = { "*" = "arn:aws:s3:::two" } } }
  }
  expect_failures = [var.destinations]
}

run "invalid_lambda_invocation" {
  command = plan
  variables {
    destinations = { invalid = { arguments = { use_response_streaming = true, use_async_invoke = true } } }
  }
  expect_failures = [var.destinations]
}

run "invalid_cidr" {
  command = plan
  variables { client_restrictions = { networks = ["not-a-cidr"] } }
  expect_failures = [var.client_restrictions]
}

run "invalid_unknown_peer_key" {
  command = plan
  variables {
    protocol  = "wg"
    wireguard = { unknown_peer_pre_shared_key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" }
  }
  expect_failures = [var.wireguard]
}

run "duplicate_destination" {
  command = plan
  variables {
    destinations      = { duplicate = {} }
    destination_names = ["duplicate"]
  }
  expect_failures = [var.destination_names]
}

run "invalid_batching" {
  command = plan
  variables {
    destinations = { invalid = { batching = { count = 1.5, timeout_in_seconds = -1, size_in_mb = 0 } } }
  }
  expect_failures = [var.destinations]
}

run "invalid_formatter" {
  command = plan
  variables { destinations = { invalid = { formatter = "json" } } }
  expect_failures = [var.destinations]
}

run "invalid_argument_formatter" {
  command = plan
  variables { destinations = { invalid = { arguments = { topic_suffix_formatter = "coap" } } } }
  expect_failures = [var.destinations]
}

run "invalid_timestamp_units" {
  command = plan
  variables { destinations = { invalid = { arguments = { timestamp_time_unit = "ticks" } } } }
  expect_failures = [var.destinations]
}

run "invalid_key" {
  command = plan
  variables {
    protocol  = "wg"
    wireguard = { peers = [{ public_key = "invalid" }] }
  }
  expect_failures = [var.wireguard]
}

run "invalid_psk" {
  command = plan
  variables {
    protocol = "dtls"
    dtls     = { psks = { device = " " } }
  }
  expect_failures = [var.dtls]
}

run "invalid_microvm_runtime_log_group" {
  command = plan
  variables { destinations = { invalid = { arguments = { runtime_log_group_name = "has space" } } } }
  expect_failures = [var.destinations]
}

run "invalid_microvm_tenant_log_stream_without_tenant" {
  command = plan
  variables { destinations = { invalid = { arguments = { use_tenant_id_for_log_stream_name = true } } } }
  expect_failures = [var.destinations]
}
