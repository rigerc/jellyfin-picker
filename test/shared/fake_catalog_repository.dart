import 'dart:async';

import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_page.dart';
import 'package:jellyfin_picker/features/catalog/domain/repositories/catalog_repository.dart';

final class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository(this.page);

  final CatalogPage page;

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) async* {
    yield page;
  }
}

final class ControlledCatalogRepository implements CatalogRepository {
  final controllers = <StreamController<CatalogPage>>[];

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) {
    final controller = StreamController<CatalogPage>();
    controllers.add(controller);
    return controller.stream;
  }
}

final class SequenceCatalogRepository implements CatalogRepository {
  SequenceCatalogRepository(this.pages);

  final List<CatalogPage> pages;

  @override
  Stream<CatalogPage> streamPages({
    CatalogFilter filter = const CatalogFilter(),
  }) async* {
    yield* Stream<CatalogPage>.fromIterable(pages);
  }
}
