import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_candidate.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_facets.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_result.dart';

abstract interface class CatalogRepository {
  Future<CatalogPage> loadPage({
    CatalogFilter filter = const CatalogFilter(),
    int startIndex = 0,
    Set<String> excludedIds = const <String>{},
    Set<String> includedIds = const <String>{},
  });

  Future<CatalogResult<List<CatalogLibrary>>> loadLibraries();

  Future<CatalogResult<CatalogFacets>> loadFacets({String? parentId});

  Future<CatalogResult<CatalogCandidate>> loadDetails(String itemId);

  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  });
}
