// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(revenueMetrics)
final revenueMetricsProvider = RevenueMetricsProvider._();

final class RevenueMetricsProvider extends $FunctionalProvider<
        AsyncValue<RevenueMetrics>, RevenueMetrics, FutureOr<RevenueMetrics>>
    with $FutureModifier<RevenueMetrics>, $FutureProvider<RevenueMetrics> {
  RevenueMetricsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'revenueMetricsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$revenueMetricsHash();

  @$internal
  @override
  $FutureProviderElement<RevenueMetrics> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RevenueMetrics> create(Ref ref) {
    return revenueMetrics(ref);
  }
}

String _$revenueMetricsHash() => r'f32c1f7f39c48740ac67d35dd44cc24803e33a59';
