import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';

abstract interface class CatalogRepository {
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  });
}
