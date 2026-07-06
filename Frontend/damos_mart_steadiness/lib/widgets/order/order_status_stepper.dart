import 'package:flutter/material.dart';

class OrderStatusStep {
  const OrderStatusStep({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({
    super.key,
    required this.activeIndex,
    this.steps = defaultSteps,
  });

  static const List<OrderStatusStep> defaultSteps = [
    OrderStatusStep(
      label: 'Pembayaran\nBerhasil',
      icon: Icons.check_rounded,
      activeIcon: Icons.check_rounded,
    ),
    OrderStatusStep(
      label: 'Diproses',
      icon: Icons.sync_rounded,
      activeIcon: Icons.sync_rounded,
    ),
    OrderStatusStep(
      label: 'Siap\nDiambil',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_outlined,
    ),
    OrderStatusStep(
      label: 'Selesai',
      icon: Icons.flag_outlined,
      activeIcon: Icons.check_rounded,
    ),
  ];

  final int activeIndex;
  final List<OrderStatusStep> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepNode(
            step: steps[i],
            isCompleted: i < activeIndex,
            isActive: i == activeIndex,
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Container(
                  height: 2,
                  color: i < activeIndex ? _Ds.primary : _Ds.lineInactive,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Ds {
  static const Color primary = Color(0xFF1B8C2E);
  static const Color textActive = Color(0xFF1B8C2E);
  static const Color textInactive = Color(0xFF9CA3AF);
  static const Color lineInactive = Color(0xFFE5E7EB);
  static const Color circleInactive = Color(0xFFF3F4F6);
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.step,
    required this.isCompleted,
    required this.isActive,
  });

  final OrderStatusStep step;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isDone = isCompleted || isActive;
    final circleColor = isDone ? _Ds.primary : _Ds.circleInactive;
    final iconColor = isDone ? Colors.white : _Ds.textInactive;
    final icon = isActive ? step.activeIcon : (isCompleted ? Icons.check_rounded : step.icon);

    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: isDone ? null : Border.all(color: _Ds.lineInactive),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            step.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isDone ? _Ds.textActive : _Ds.textInactive,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
