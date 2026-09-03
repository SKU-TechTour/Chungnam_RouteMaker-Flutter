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
        _ =>
          state.receipts.isEmpty
              ? const Center(child: Text('완주 후 공유할 여행 기록이 여기에 표시돼요.'))
              : ListView.builder(
                  itemCount: state.receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = state.receipts[index];
                    final date = receipt.visitedAt;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(receipt.title),
                        subtitle: Text(
                          '${receipt.amount}곳 · ${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    );
                  },
                ),
      },
    );
  }
}
