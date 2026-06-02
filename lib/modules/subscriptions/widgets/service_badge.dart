// lib/modules/subscriptions/widgets/service_badge.dart
//
// Shows the service type with icon + label in a colored badge.
// Used on the Add Subscription screen header and subscription list cards.

import 'package:flutter/material.dart';
import '../../../core/constants/service_constants.dart';

class ServiceBadge extends StatelessWidget {
  final String service;
  final bool large;

  const ServiceBadge({
    super.key,
    required this.service,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ServiceConstants.colorFor(service);
    final icon  = ServiceConstants.iconFor(service);
    final label = ServiceConstants.labelFor(service);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical:   large ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: large ? 20 : 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize:   large ? 15 : 12,
              fontWeight: FontWeight.w700,
              color:      color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
