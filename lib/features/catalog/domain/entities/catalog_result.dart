import 'package:jellyfin_picker/features/catalog/domain/failures/catalog_failure.dart';

final class CatalogResult<T> {
  const CatalogResult.success(this.value) : failure = null;

  const CatalogResult.failure(this.failure) : value = null;

  final T? value;
  final CatalogFailure? failure;
}
