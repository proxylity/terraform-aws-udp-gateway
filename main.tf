locals {
  destination_arguments = {
    for name, dest in var.destinations : name => dest.arguments == null ? null : {
      for key, value in {
        DynamicTopicSuffix               = dest.arguments.dynamic_topic_suffix
        TopicSuffixExpression            = dest.arguments.topic_suffix_expression
        TopicSuffixFormatter             = dest.arguments.topic_suffix_formatter
        TenantId                         = dest.arguments.tenant_id
        TenantIdExpression               = dest.arguments.tenant_id_expression
        TenantIdFormatter                = dest.arguments.tenant_id_formatter
        UseResponseStreaming             = dest.arguments.use_response_streaming
        UseAsyncInvoke                   = dest.arguments.use_async_invoke
        IdleDurationSeconds              = dest.arguments.idle_duration_seconds
        ExecutionRoleArn                 = dest.arguments.execution_role_arn
        RunHookExtraData                 = dest.arguments.run_hook_extra_data
        EgressNetworkConnectorArns       = dest.arguments.egress_network_connector_arns
        RuntimeLogGroupName              = dest.arguments.runtime_log_group_name
        UseTenantIdForLogStreamName      = dest.arguments.use_tenant_id_for_log_stream_name
        SendRaw                          = dest.arguments.send_raw
        UseMessageAttributes             = dest.arguments.use_message_attributes
        MessageGroupIdExpression         = dest.arguments.message_group_id_expression
        MessageGroupIdFormatter          = dest.arguments.message_group_id_formatter
        MessageDeduplicationIdExpression = dest.arguments.message_deduplication_id_expression
        MessageDeduplicationIdFormatter  = dest.arguments.message_deduplication_id_formatter
        PartitionKeyExpression           = dest.arguments.partition_key_expression
        PartitionKeyExpressionFormatter  = dest.arguments.partition_key_expression_formatter
        DeviceIdExpression               = dest.arguments.device_id_expression
        LatitudeExpression               = dest.arguments.latitude_expression
        LongitudeExpression              = dest.arguments.longitude_expression
        ScaleFactor                      = dest.arguments.scale_factor
        AccuracyExpression               = dest.arguments.accuracy_expression
        PositionPropertyExpressions      = dest.arguments.position_property_expressions
        TimestampExpression              = dest.arguments.timestamp_expression
        TimestampTimeUnit                = dest.arguments.timestamp_time_unit
      } : key => value if value != null
    }
  }

  inline_destinations = [
    for name, dest in var.destinations : {
      for key, value in {
        Name        = name
        Description = dest.description
        # JSON round-tripping preserves the string-or-object wire type without HCL coercion.
        DestinationArn = jsondecode(
          dest.destination_arn != null ? jsonencode(dest.destination_arn) : jsonencode(
            dest.destination_arns != null ? dest.destination_arns : {}
          )
        )
        Role = dest.role == null ? null : {
          for key, value in { Arn = dest.role.arn, Duration = dest.role.duration } : key => value if value != null
        }
        Batching = dest.batching == null ? null : {
          for key, value in {
            Count            = dest.batching.count
            TimeoutInSeconds = dest.batching.timeout_in_seconds
            SizeInMB         = dest.batching.size_in_mb
          } : key => value if value != null
        }
        MetricsEnabled   = dest.metrics_enabled
        Formatter        = dest.formatter
        FilterExpression = dest.filter_expression
        LogGroupName     = dest.log_group_name
        Arguments        = local.destination_arguments[name]
      } : key => value if value != null
    }
  ]

  wireguard_properties = jsondecode(var.wireguard == null ? "{}" : jsonencode({
    for key, value in {
      DecapsulatedDelivery    = var.wireguard.decapsulated_delivery
      AllowUnknownPeers       = var.wireguard.allow_unknown_peers
      UnknownPeerPreSharedKey = var.wireguard.unknown_peer_pre_shared_key
      KeyRefreshToken         = var.wireguard.key_refresh_token
      Peers = [for peer in var.wireguard.peers : {
        for key, value in {
          PublicKey    = peer.public_key
          SharedSecret = peer.shared_secret
          AllowedIPs   = peer.allowed_ips
        } : key => value if value != null
      }]
    } : key => value if value != null
  }))

  dtls_properties = jsondecode(var.dtls == null ? "{}" : jsonencode({
    for key, value in {
      Psks                   = var.dtls.psks
      ServerSecret           = var.dtls.server_secret
      RequireCookies         = var.dtls.require_cookies
      AllowEarlyData         = var.dtls.allow_early_data
      EarlyDataWindowSeconds = var.dtls.early_data_window_seconds
      CertRefreshToken       = var.dtls.cert_refresh_token
    } : key => value if value != null
  }))

  webrtc_properties = jsondecode(var.webrtc == null ? "{}" : jsonencode({
    for key, value in {
      ServerSecret                = var.webrtc.server_secret
      RequireCookies              = var.webrtc.require_cookies
      CertRefreshToken            = var.webrtc.cert_refresh_token
      WebRtcSignalingMode         = var.webrtc.signaling_mode
      WebRtcSignalingRefreshToken = var.webrtc.signaling_refresh_token
    } : key => value if value != null
  }))

  # Only public signaling has token/URL attributes. Do not request absent GetAtt attributes.
  public_signaling = var.protocol == "webrtc" && (var.webrtc == null ? false : nonsensitive(var.webrtc.signaling_mode) == "public")

  protocol_outputs = merge(
    var.protocol == "wg" ? { WireGuardPublicKey = { Value = { "Fn::GetAtt" = ["ProxylityListener", "WireGuardPublicKey"] } } } : {},
    contains(["dtls", "webrtc"], var.protocol) ? { DtlsServerCertificate = { Value = { "Fn::GetAtt" = ["ProxylityListener", "DtlsServerCertificate"] } } } : {},
    var.protocol == "webrtc" ? {
      for attr in ["WebRtcFingerprint", "WebRtcSctpPort", "WebRtcChannelId", "WebRtcSignalingMode"] :
      attr => { Value = { "Fn::GetAtt" = ["ProxylityListener", attr] } }
    } : {},
    local.public_signaling ? {
      for attr in ["WebRtcSignalingToken", "WebRtcSignalingUrl"] :
      attr => { Value = { "Fn::GetAtt" = ["ProxylityListener", attr] } }
    } : {}
  )
}

resource "aws_cloudformation_stack" "proxylity_listener" {
  name = var.stack_name

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Mappings = {
      ProxylityConfig = {
        "Fn::Transform" = {
          Name = "AWS::Include"
          Parameters = {
            Location = {
              "Fn::Sub" = "s3://proxylity-config-$${AWS::Region}/$${AWS::AccountId}/customer-config.json"
            }
          }
        }
      }
    }
    Resources = {
      ProxylityListener = {
        Type = "Custom::ProxylityUdpGatewayListener"
        Properties = merge(
          {
            ServiceToken = { "Fn::FindInMap" = ["ProxylityConfig", { Ref = "AWS::Region" }, "ServiceToken"] }
            ApiKey       = { "Fn::FindInMap" = ["ProxylityConfig", "Account", "ApiKey"] }
            Protocols    = [var.protocol]
            ClientRestrictions = {
              Networks = var.client_restrictions.networks
              Domains  = var.client_restrictions.domains
            }
            Destinations = concat(local.inline_destinations, sort(tolist(var.destination_names)))
          },
          { for key, value in {
            Name           = var.listener_name
            Description    = var.description
            MetricsEnabled = var.metrics_enabled
            LogGroupName   = var.log_group_name
            Role = var.role == null ? null : {
              for key, value in { Arn = var.role.arn, Duration = var.role.duration } : key => value if value != null
            }
          } : key => value if value != null },
          local.wireguard_properties, local.dtls_properties, local.webrtc_properties
        )
      }
    }
    Outputs = merge({
      ListenerName = { Value = { "Fn::GetAtt" = ["ProxylityListener", "Id"] } }
      Port         = { Value = { "Fn::GetAtt" = ["ProxylityListener", "Port"] } }
      Domain       = { Value = { "Fn::GetAtt" = ["ProxylityListener", "Domain"] } }
      DestinationNames = {
        Value = { "Fn::Join" = [",", { "Fn::GetAtt" = ["ProxylityListener", "DestinationNames"] }] }
      }
    }, local.protocol_outputs)
  })

  capabilities = ["CAPABILITY_AUTO_EXPAND"]
  tags         = var.tags
}
