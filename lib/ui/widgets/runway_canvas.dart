import 'package:air_traffic_sim/ui/models/runway_config_ui.dart';
import 'package:flutter/material.dart';

class RunwayCanvas extends StatelessWidget {
  final List<RunwayConfigUI> runways;
  final VoidCallback onAdd;
  final Function(int) onRemove;
  final Function(int) onEdit;

  const RunwayCanvas({
    super.key,
    required this.runways,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 825,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(runways.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16), // space between runways
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => onEdit(index),
                        child: _RunwayGraphic(index: index, runway: runways[index]),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () => onRemove(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            )
          )),
          

          Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              mini: true,
              onPressed: onAdd,
              child: const Icon(Icons.add),
            ),
          ),

        ],
      ),
    );
  }
}

class _RunwayGraphic extends StatelessWidget {
  final int index;
  final RunwayConfigUI runway;

  const _RunwayGraphic({
    required this.index,
    required this.runway,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 200,
      decoration: BoxDecoration(
        color: runway.isInvalid ? Colors.red : Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          "Runway ${index + 1}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}