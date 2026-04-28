import 'package:flutter/material.dart';

class RouteInputDialog extends StatefulWidget {
  final List<String> initialRoute;

  const RouteInputDialog({
    super.key,
    this.initialRoute = const [],
  });

  @override
  State<RouteInputDialog> createState() => _RouteInputDialogState();
}

class _RouteInputDialogState extends State<RouteInputDialog> {
  late List<String> _route;
  final TextEditingController _sectorController = TextEditingController();

  // Common Islamabad sectors
  final List<String> _commonSectors = [
    'F-6', 'F-7', 'F-8', 'F-10', 'F-11',
    'G-6', 'G-7', 'G-8', 'G-9', 'G-10', 'G-11', 'G-13', 'G-14',
    'I-8', 'I-9', 'I-10',
    'Blue Area', 'Zero Point', 'Faizabad',
    'PWD', 'Golra', 'Tramri', 'Koral',
  ];

  @override
  void initState() {
    super.initState();
    _route = List.from(widget.initialRoute);
  }

  @override
  void dispose() {
    _sectorController.dispose();
    super.dispose();
  }

  void _addSector(String sector) {
    if (sector.trim().isEmpty) return;
    if (_route.contains(sector.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$sector already added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _route.add(sector.trim());
    });
    _sectorController.clear();
  }

  void _removeSector(int index) {
    setState(() {
      _route.removeAt(index);
    });
  }

  void _reorderSector(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _route.removeAt(oldIndex);
      _route.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.route, color: Color(0xFF2196F3)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add Your Route',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add the sectors/areas you pass through (in order)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current Route Display
                    if (_route.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.route, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'Your Route (${_route.length} stops)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _route.join(' → '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Route List (Reorderable)
                    if (_route.isNotEmpty) ...[
                      const Text(
                        'Drag to reorder:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25,
                        ),
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          itemCount: _route.length,
                          onReorder: _reorderSector,
                          itemBuilder: (context, index) {
                            return ListTile(
                              key: ValueKey(_route[index] + index.toString()),
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.drag_handle, size: 20),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF2196F3),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                _route[index],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.red,
                                onPressed: () => _removeSector(index),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Input Field
                    TextField(
                      controller: _sectorController,
                      decoration: InputDecoration(
                        labelText: 'Add sector/area',
                        hintText: 'e.g., G-10, Blue Area',
                        prefixIcon: const Icon(Icons.add_location),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: _addSector,
                    ),
                    const SizedBox(height: 12),

                    // Common Sectors (Quick Add)
                    const Text(
                      'Quick add:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonSectors
                          .where((sector) => !_route.contains(sector))
                          .map((sector) => InkWell(
                        onTap: () => _addSector(sector),
                        child: Chip(
                          label: Text(
                            sector,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _route.length >= 2
                        ? () => Navigator.pop(context, _route)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _route.length >= 2 ? 'Save Route' : 'Min 2 stops',
                      style: const TextStyle(fontSize: 13,color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}