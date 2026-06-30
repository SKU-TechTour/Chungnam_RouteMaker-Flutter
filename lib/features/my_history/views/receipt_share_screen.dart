import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterprojects/core/di/providers.dart';
import 'package:flutterprojects/core/widgets/error_widget.dart';
import 'package:flutterprojects/core/widgets/loading_widget.dart';

/// [SB 화면 4] 영수증 카드 원터치 공유 화면.
class ReceiptShareScreen extends ConsumerStatefulWidget {
  const ReceiptShareScreen({super.key});

  @override
  ConsumerState<ReceiptShareScreen> createState() => _ReceiptShareScreenState();
}

class _ReceiptShareScreenState extends ConsumerState<ReceiptShareScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(myHistoryViewModelProvider.notifier).loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myHistoryViewModelProvider);
    final notifier = ref.read(myHistoryViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('영수증 공유')),
      body: switch ((state.isLoading, state.errorMessage)) {
        (true, _) => const LoadingWidget(),
        (_, String msg) => AppErrorWidget(
            message: msg,
            onRetry: notifier.loadHistory,
          ),
        _ => ListView.builder(
            itemCount: state.receipts.length,
            itemBuilder: (context, index) {
              final receipt = state.receipts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(receipt.title),
                  subtitle: Text('${receipt.amount}원 · ${receipt.visitedAt}'),
                  trailing: IconButton(
                    icon: state.isSharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    onPressed: state.isSharing
                        ? null
                        : () => notifier.shareReceipt(receipt.id),
                  ),
                ),
              );
            },
          ),
      },
    );
  }
}
