// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportController)
final reportControllerProvider = ReportControllerProvider._();

final class ReportControllerProvider
    extends $NotifierProvider<ReportController, AsyncValue<ReportData?>> {
  ReportControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'reportControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$reportControllerHash();

  @$internal
  @override
  ReportController create() => ReportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<ReportData?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<ReportData?>>(value),
    );
  }
}

String _$reportControllerHash() => r'eb8c24f533623af0cd7c5801beb981c811ee29d5';

abstract class _$ReportController extends $Notifier<AsyncValue<ReportData?>> {
  AsyncValue<ReportData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ReportData?>, AsyncValue<ReportData?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<ReportData?>, AsyncValue<ReportData?>>,
        AsyncValue<ReportData?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
