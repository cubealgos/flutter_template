// Test literals, `late` set-up fixtures and a group's long body are plain in a
// test and read worse as named constants or splits.
// ignore_for_file: solid_lints/no_magic_number, solid_lints/avoid_late_keyword, solid_lints/prefer_match_file_name, solid_lints/number_of_parameters, solid_lints/function_lines_of_code, solid_lints/avoid_non_null_assertion

import 'dart:convert';

/// A Paddle `subscription.*` webhook body for [type], as Paddle documents the
/// envelope: `event_id`, `event_type`, `occurred_at`, `notification_id` and
/// `data` (the subscription entity).
String subscriptionEvent({
  Map<String, dynamic>? scheduledChange,
  String id = 'evt_01',
  String type = 'subscription.updated',
  String occurredAt = '2026-10-01T12:00:00Z',
  String status = 'active',
  int quantity = 3,
  String priceId = 'pri_pro',
  Object? owner = 'team:team1',
}) => jsonEncode(<String, dynamic>{
  'event_id': id,
  'event_type': type,
  'occurred_at': occurredAt,
  'notification_id': 'ntf_$id',
  'data': subscriptionEntity(
    status: status,
    quantity: quantity,
    priceId: priceId,
    owner: owner,
    scheduledChange: scheduledChange,
  ),
});

/// The subscription entity of Paddle's API and webhooks.
Map<String, dynamic> subscriptionEntity({
  Map<String, dynamic>? scheduledChange,
  String status = 'active',
  int quantity = 3,
  String priceId = 'pri_pro',
  Object? owner = 'team:team1',
}) => <String, dynamic>{
  'id': 'sub_01',
  'status': status,
  'customer_id': 'ctm_01',
  'updated_at': '2026-10-01T12:00:00Z',
  'next_billed_at': '2026-11-01T12:00:00Z',
  'canceled_at': null,
  'current_billing_period': <String, dynamic>{
    'starts_at': '2026-10-01T12:00:00Z',
    'ends_at': '2026-11-01T12:00:00Z',
  },
  'scheduled_change': scheduledChange,
  'items': <Map<String, dynamic>>[
    <String, dynamic>{
      'status': 'active',
      'quantity': quantity,
      'price': <String, dynamic>{'id': priceId},
    },
  ],
  'custom_data': owner == null ? null : <String, dynamic>{'owner': owner},
};
