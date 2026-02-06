part of '../flutter_secure_storage_platform_interface.dart';

/// The `Options` class provides a base abstraction for defining configuration
/// options in a structured way.
///
/// This class is designed to be extended by platform-specific or
/// use-case-specific implementations that convert their options into a map
/// representation.
abstract class Options {
  /// Creates an instance of the `Options` class.
  ///
  /// This constructor is intended to be used by subclasses to initialize
  /// their configuration options.
  const Options();

  /// A getter that retrieves the options as a map representation.
  ///
  /// This property calls the `toMap` method to convert the options into
  /// a map of key-value pairs.
  ///
  /// Returns:
  /// - A map containing the configuration options.
  Map<String, String> get params => toMap();

  /// Converts the options into a map representation.
  ///
  /// This method is intended to be overridden by subclasses to provide
  /// a specific mapping of their configuration properties.
  ///
  /// Returns:
  /// - A map containing the configuration options.
  @protected
  Map<String, String> toMap();
}
