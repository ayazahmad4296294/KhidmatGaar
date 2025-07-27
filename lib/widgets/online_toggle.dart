import 'package:flutter/material.dart';

class OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final Function(bool) onToggle;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            left: isOnline ? 75 : 0,
            top: 3,
            child: Container(
              width: 75,
              height: 30,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : const Color(0xFFE74C3C),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(false),
                  child: Center(
                    child: Text(
                      'Offline',
                      style: TextStyle(
                        color: !isOnline ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onToggle(true),
                  child: Center(
                    child: Text(
                      'Online',
                      style: TextStyle(
                        color: isOnline ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
