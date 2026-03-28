import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/hydration_viewmodel.dart';
import '../models/hydration_model.dart';

class HydrationLogScreen extends StatefulWidget {
  const HydrationLogScreen({super.key});

  @override
  State<HydrationLogScreen> createState() => _HydrationLogScreenState();
}

class _HydrationLogScreenState extends State<HydrationLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HydrationViewModel>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration Log'),
        elevation: 0,
      ),
      body: Consumer<HydrationViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Container(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Main content (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 24, bottom: 16),
                    child: Column(
                      children: [
                        _buildHydrationCircle(viewModel),
                        const SizedBox(height: 18),
                        _buildQuickAddButtons(context, viewModel),
                        const SizedBox(height: 20),
                        _buildLogEntries(context, viewModel),
                        const SizedBox(height: 16),
                        _buildHintNote(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHydrationCircle(HydrationViewModel viewModel) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: _CircleProgressPainter(progress: viewModel.progress),
          ),
        ),
        GestureDetector(
          onTap: () => _showEditGoalDialog(context),
          child: Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${viewModel.consumptionInLiters.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Consumed',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () => _showEditGoalDialog(context),
                  child: Text(
                    'Goal ${viewModel.goalInLiters.toStringAsFixed(1)} L',
                    style: const TextStyle(color: Color(0xFFFFA500), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButtons(BuildContext context, HydrationViewModel viewModel) {
    return Row(
      children: [
        _quickAddButton(
          context,
          viewModel,
          '50ml',
          50,
        ),
        const SizedBox(width: 8),
        _quickAddButton(
          context,
          viewModel,
          '100ml',
          100,
        ),
        const SizedBox(width: 8),
        _quickAddButton(
          context,
          viewModel,
          'Custom',
          null, // null means custom
        ),
      ],
    );
  }

  Widget _quickAddButton(
    BuildContext context,
    HydrationViewModel viewModel,
    String label,
    int? amountMl,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (amountMl != null) {
            await viewModel.addEntry(amountMl);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $amountMl ml'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            if (mounted) {
              _showCustomAmountDialog(context, viewModel);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFA500),
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33FFA500),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.black, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogEntries(BuildContext context, HydrationViewModel viewModel) {
    if (viewModel.todayEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No hydration entries yet. Start by adding water intake!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: viewModel.todayEntries.map((entry) {
        return Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.startToEnd,
          background: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white, size: 24),
          ),
          confirmDismiss: (direction) async {
            return true; // Allow swipe, we'll handle undo
          },
          onDismissed: (direction) async {
            if (entry.id != null) {
              final deletedEntry = await viewModel.deleteEntry(entry.id!);

              if (mounted && deletedEntry != null) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Entry deleted'),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    dismissDirection: DismissDirection.horizontal,
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        viewModel.undoDeleteEntry(deletedEntry);
                      },
                    ),
                  ),
                );
                // Auto-dismiss after 3 seconds if not already dismissed
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    scaffoldMessenger.hideCurrentSnackBar();
                  }
                });
              }
            }
          },
          child: GestureDetector(
            onTap: () {
              _showEditEntryDialog(context, viewModel, entry);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFF262626)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '${entry.amountMl}ml',
                          style: const TextStyle(
                            color: Color(0xFFFFA500),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        entry.time,
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.edit, color: Color(0xFFFFA500), size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHintNote() {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), style: BorderStyle.solid),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_forward, color: Color(0xFFFFA500), size: 16),
          const SizedBox(width: 6),
          const Text(
            'Swipe right to delete · Tap entry to edit',
            style: TextStyle(color: Color(0xFF555555), fontSize: 12),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.edit, color: Color(0xFFFFA500), size: 16),
        ],
      ),
    );
  }

  void _showCustomAmountDialog(BuildContext context, HydrationViewModel viewModel) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Add Custom Amount',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter amount in ml',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            suffixText: 'ml',
            suffixStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFA500)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFA500)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await viewModel.addCustomEntry(amount);
                if (mounted && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $amount ml'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Add',
              style: TextStyle(color: Color(0xFFFFA500)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditEntryDialog(
    BuildContext context,
    HydrationViewModel viewModel,
    HydrationEntry entry,
  ) {
    final controller = TextEditingController(text: entry.amountMl.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Edit Entry',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter amount in ml',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            suffixText: 'ml',
            suffixStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFA500)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFA500)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newAmount = int.tryParse(controller.text);
              if (newAmount != null && newAmount > 0 && entry.id != null) {
                await viewModel.updateEntry(entry.id!, newAmount);
                if (mounted && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated to $newAmount ml'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Update',
              style: TextStyle(color: Color(0xFFFFA500)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context) {
    final viewModel = context.read<HydrationViewModel>();
    final goalController = TextEditingController(
      text: viewModel.dailyGoal.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Edit Daily Goal',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: goalController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter daily hydration goal in ml',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            suffixText: 'ml',
            suffixStyle: const TextStyle(color: Color(0xFFAAAAAA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFA500)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF333333)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFA500)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () {
              final newGoal = int.tryParse(goalController.text);
              if (newGoal != null && newGoal > 0) {
                viewModel.updateGoalMl(newGoal);
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal updated to ${newGoal / 1000} L'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Update',
              style: TextStyle(color: Color(0xFFFFA500)),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable circular progress painter (same as left screen, but we keep it here for completeness)
class _CircleProgressPainter extends CustomPainter {
  final double progress;

  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background grey ring
    final backgroundPaint = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawArc(rect, -3.142 / 2, 2 * 3.142, false, backgroundPaint);

    // Orange progress ring
    final progressPaint = Paint()
      ..color = const Color(0xFFFFA500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.142 * progress;
    canvas.drawArc(rect, -3.142 / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
