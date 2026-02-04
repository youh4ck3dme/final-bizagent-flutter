import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/ico_lookup_result.dart';
import '../services/company_repository.dart';
import '../../auth/providers/auth_repository.dart';

enum IcoLookupStatus {
  idle,
  loading,
  cachedFresh,
  cachedStaleRefreshing,
  success,
  notFound,
  errorOffline,
  errorServer,
}

class IcoLookupState {
  final IcoLookupStatus status;
  final IcoLookupResult? result;
  final String? errorMessage;

  IcoLookupState({required this.status, this.result, this.errorMessage});

  IcoLookupState copyWith({
    IcoLookupStatus? status,
    IcoLookupResult? result,
    String? errorMessage,
  }) {
    return IcoLookupState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final icoLookupProvider = NotifierProvider<IcoLookupController, IcoLookupState>(
  () {
    return IcoLookupController();
  },
);

class IcoLookupController extends Notifier<IcoLookupState> {
  @override
  IcoLookupState build() {
    return IcoLookupState(status: IcoLookupStatus.idle);
  }

  Future<void> lookup(String ico, {bool isAuto = false}) async {
    if (ico.length != 8) return;

    // Reset error on new search
    state = state.copyWith(status: IcoLookupStatus.loading);

    final repo = ref.read(companyRepositoryProvider);
    final user = ref.read(authStateProvider).asData?.value;

    try {
      // 1. Check local cache FIRST
      final cached = await repo.getFromCache(ico);
      final now = DateTime.now();

      if (cached != null) {
        final isFresh =
            cached.expiresAt != null && cached.expiresAt!.isAfter(now);

        if (isFresh) {
          state = state.copyWith(
            status: IcoLookupStatus.cachedFresh,
            result: cached,
          );
          // If we are fresh, we are done
          if (user != null) await repo.markAsOpened(user.id, ico);
          return;
        } else {
          // STALE: Show immediately but trigger background refresh
          state = state.copyWith(
            status: IcoLookupStatus.cachedStaleRefreshing,
            result: cached,
          );
        }
      }

      // 2. Refresh from backend (Background or Initial)
      final refreshed = await repo.refresh(ico, existingHash: cached?.hash);

      // 3. Handle result
      if (refreshed != null) {
        state = state.copyWith(
          status: IcoLookupStatus.success,
          result: refreshed,
        );
      } else if (cached != null) {
        // null means hash was SAME, no update needed, just mark as success
        state = state.copyWith(status: IcoLookupStatus.success);
      } else {
        // Truly not found
        state = state.copyWith(status: IcoLookupStatus.notFound);
      }

      // Mark as opened if successful
      if (user != null && (refreshed != null || cached != null)) {
        await repo.markAsOpened(user.id, ico);
      }
    } catch (e) {
      // If we have cached data, don't strictly show error screen, maybe just a toast
      if (state.result != null) {
        state = state.copyWith(status: IcoLookupStatus.success);
        // Error is "silent" since we have stale data
      } else {
        if (e.toString().contains('SocketException')) {
          state = state.copyWith(status: IcoLookupStatus.errorOffline);
        } else {
          state = state.copyWith(
            status: IcoLookupStatus.errorServer,
            errorMessage: e.toString(),
          );
        }
      }
    }
  }

  void reset() {
    state = IcoLookupState(status: IcoLookupStatus.idle);
  }
}
