import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../calculatorScreen/InterestCalculatorScreen.dart';
import '../models/interest_response.dart';
import '../models/interest_history.dart';
import '../services/interest_service.dart';

final interestServiceProvider =
Provider((ref) => InterestService());

final interestCalculatorProvider =
StateNotifierProvider<InterestCalculatorNotifier, InterestState>(
      (ref) => InterestCalculatorNotifier(ref),
);

/// -------------------- STATE --------------------

class InterestState {
  final bool loading;
  final InterestResult? result;
  final List<InterestHistory> history;
  final String? error;

  const InterestState({
    this.loading = false,
    this.result,
    this.history = const [],
    this.error,
  });

  InterestState copyWith({
    bool? loading,
    InterestResult? result,
    List<InterestHistory>? history,
    String? error,
  }) {
    return InterestState(
      loading: loading ?? this.loading,
      result: result ?? this.result,
      history: history ?? this.history,
      error: error,
    );
  }
}

/// -------------------- NOTIFIER --------------------

class InterestCalculatorNotifier extends StateNotifier<InterestState> {
  InterestCalculatorNotifier(this.ref) : super(const InterestState());

  final Ref ref;
  final List<InterestHistory> _pendingDeletes = [];
  final Map<int, Timer> _deleteTimers = {};
  /// -------- CALCULATE INTEREST --------
  Future<void> calculate({
    required double principal,
    required double rate,
    required DateTime startDate,
    required DateTime endDate,
    required int compoundingFrequency,
    required InterestType type,
  }) async {
    try {
      state = state.copyWith(loading: true, error: null);

      final int timeInMonths =
      ((endDate.difference(startDate).inDays) / 30).round();

      final service = ref.read(interestServiceProvider);

      late InterestResult result;

      if (type == InterestType.simple) {
        result = await service.calculateSimpleInterest(
          principal: principal,
          rate: rate,
          timeInMonths: timeInMonths,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        result = await service.calculateCompoundInterest(
          principal: principal,
          rate: rate,
          timeInMonths: timeInMonths,
          startDate: startDate,
          endDate: endDate,
          compoundingFrequency: compoundingFrequency,
        );
      }

      state = state.copyWith(
        loading: false,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchHistory() async {
    try {
      state = state.copyWith(loading: true, error: null);
      final history = await ref.read(interestServiceProvider).getInterestHistory();
      state = state.copyWith(
        loading: false,
        history: history,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  void deleteWithUndo(InterestHistory item, BuildContext context) {
    state = state.copyWith(
      history: state.history.where((e) => e.id != item.id).toList(),
    );
    _pendingDeletes.add(item);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("History deleted"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () => _undoDelete(item),
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    _deleteTimers[item.id] = Timer(
      const Duration(seconds: 4),
          () => _commitDelete(item),
    );
  }

  Future<void> _commitDelete(InterestHistory item) async {
    try {
      _pendingDeletes.removeWhere((e) => e.id == item.id);
      _deleteTimers.remove(item.id);

      await ref.read(interestServiceProvider).deleteHistory(item.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _undoDelete(InterestHistory item) {
    _deleteTimers[item.id]?.cancel();
    _deleteTimers.remove(item.id);
    _pendingDeletes.removeWhere((e) => e.id == item.id);

    state = state.copyWith(
      history: [...state.history, item]
        ..sort(
              (a, b) =>
              b.calculationDate.compareTo(a.calculationDate),
        ),
    );
  }

  Future<void> clearHistory() async {
    try {
      state = state.copyWith(loading: true);
      await ref.read(interestServiceProvider).clearHistory();
      state = state.copyWith(
        loading: false,
        history: [],
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  void clearResult() {
    state = state.copyWith(result: null);
  }
}
