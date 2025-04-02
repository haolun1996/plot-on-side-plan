import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Plot Points")),
        body: const ImagePointPlotter(),
      ),
    );
  }
}

class ImagePointPlotter extends StatefulWidget {
  const ImagePointPlotter({super.key});

  @override
  _ImagePointPlotterState createState() => _ImagePointPlotterState();
}

class _ImagePointPlotterState extends State<ImagePointPlotter> {
  final List<PointData> confirmedPoints = [];
  Offset? pendingPoint;
  final GlobalKey imageKey = GlobalKey();
  int roomCounter = 101;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTapDown: (details) {
                        final RenderBox? renderBox =
                            imageKey.currentContext?.findRenderObject() as RenderBox?;
                        if (renderBox == null) return;

                        final localOffset = renderBox.globalToLocal(details.globalPosition);
                        setState(() {
                          pendingPoint = Offset(
                            localOffset.dx / renderBox.size.width,
                            localOffset.dy / renderBox.size.height,
                          );
                        });
                      },
                      child: Stack(
                        children: [
                          SizedBox(
                            width: size,
                            height: size,
                            child: Image.asset(
                              'assets/floor.png',
                              key: imageKey,
                              fit: BoxFit.cover,
                            ),
                          ),
                          ...confirmedPoints.map((point) {
                            double scaledX = point.relativePosition.dx * size;
                            double scaledY = point.relativePosition.dy * size;

                            return Positioned(
                              left: scaledX,
                              top: scaledY,
                              child: GestureDetector(
                                onTap: () => _showPointInfo(context, point),
                                child: _buildDot(),
                              ),
                            );
                          }).toList(),
                          if (pendingPoint != null)
                            Positioned(
                              left: pendingPoint!.dx * size,
                              top: pendingPoint!.dy * size,
                              child: Draggable<Offset>(
                                feedback: _buildDot(),
                                childWhenDragging: const SizedBox(),
                                onDragEnd: (details) {
                                  final RenderBox? renderBox =
                                      imageKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (renderBox == null) return;

                                  final localOffset = renderBox.globalToLocal(details.offset);
                                  setState(() {
                                    pendingPoint = Offset(
                                      (localOffset.dx / size).clamp(0.0, 1.0),
                                      (localOffset.dy / size).clamp(0.0, 1.0),
                                    );
                                  });
                                },
                                child: _buildDot(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pendingPoint != null)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          confirmedPoints.add(PointData(
                            relativePosition: pendingPoint!,
                            roomNo: roomCounter,
                            floor: 2,
                            type: "Double Storey",
                          ));
                          roomCounter++;
                          pendingPoint = null;
                        });
                      },
                      child: const Text("Confirm Point"),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _showSavedPoints(context),
                    child: const Text("Save All Confirmed Points"),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
    );
  }

  void _showPointInfo(BuildContext context, PointData point) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Point Info - Room ${point.roomNo}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("📍 Room No: ${point.roomNo}"),
              Text("🏢 Floor: ${point.floor}"),
              Text("🏠 Type: ${point.type}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showSavedPoints(BuildContext context) {
    if (confirmedPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No points have been confirmed yet!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Saved Points"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: confirmedPoints
                .map((point) => ListTile(
                      title: Text("Room No: ${point.roomNo}"),
                      subtitle: Text("Floor: ${point.floor}, Type: ${point.type}"),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}

class PointData {
  final Offset relativePosition;
  final int roomNo;
  final int floor;
  final String type;

  PointData({
    required this.relativePosition,
    required this.roomNo,
    required this.floor,
    required this.type,
  });

  PointData copyWith({Offset? relativePosition}) {
    return PointData(
      relativePosition: relativePosition ?? this.relativePosition,
      roomNo: roomNo,
      floor: floor,
      type: type,
    );
  }
}
