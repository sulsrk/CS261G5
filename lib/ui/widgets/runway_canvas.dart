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
    return LayoutBuilder(
      builder: (context, constraints) {

        final canvasHeight = constraints.maxHeight;
        final canvasWidth = constraints.maxWidth;

        return Container(
          decoration: BoxDecoration(
            color: Colors.green.shade700,
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
                      padding: const EdgeInsets.only(right: 16), 
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () => onEdit(index),
                            child: _RunwayGraphic(
                                index: index, 
                                runway: runways[index],
                                canvasHeight: canvasHeight,
                                canvasWidth: canvasWidth,
                              ),
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
    );
  }
}

class _RunwayGraphic extends StatefulWidget {
  final int index;
  final RunwayConfigUI runway;
  final double canvasHeight;
  final double canvasWidth;

  const _RunwayGraphic({
    required this.index,
    required this.runway,
    required this.canvasHeight,
    required this.canvasWidth,
  });

  @override
  State<_RunwayGraphic> createState() => _RunwayGraphicState();
}

class _RunwayGraphicState extends State<_RunwayGraphic> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final runwayHeight = widget.canvasHeight * 0.95;
    final runwayWidth = widget.canvasWidth * 0.08;

    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: runwayWidth,
        height: runwayHeight,
        decoration: BoxDecoration(
          color: widget.runway.isInvalid
              ? Colors.red
              : hovering
                  ? Colors.grey.shade800
                  : Colors.black,
          borderRadius: BorderRadius.circular(runwayWidth * 0.1),
          boxShadow: hovering
              ? const [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black26,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            "--------------- ${widget.index + 1} ---------------",
            style: TextStyle(
              color: Colors.white,
              fontSize: runwayHeight * 0.06, // ✅ scales text too
            ),
          ),
        ),
      ),
    );
  }
}