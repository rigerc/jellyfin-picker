import 'package:flutter/material.dart';
import 'package:jellyfin_picker/core/media/entities/catalog_filter.dart';
import 'package:jellyfin_picker/features/catalog/domain/entities/catalog_library.dart';
import 'package:jellyfin_picker/features/discovery/presentation/widgets/discovery_filter_sections.dart';

typedef DiscoveryQueryFilterData = ({
  TextEditingController searchController,
  List<CatalogLibrary> libraries,
  String? libraryId,
  CatalogSort sort,
  CatalogAddedWindow? addedWithin,
  ValueChanged<CatalogSort> onSortChanged,
  ValueChanged<String?> onLibraryChanged,
  ValueChanged<CatalogAddedWindow?> onAddedWithinChanged,
});

typedef DiscoveryQuickFilterData = ({
  bool recent,
  bool unwatched,
  bool favorites,
  ValueChanged<bool> onRecentChanged,
  ValueChanged<bool> onUnwatchedChanged,
  ValueChanged<bool> onFavoritesChanged,
});

typedef DiscoveryRatingFilterData = ({
  RangeValues runtime,
  double community,
  double critic,
  ValueChanged<RangeValues> onRuntimeChanged,
  ValueChanged<double> onCommunityChanged,
  ValueChanged<double> onCriticChanged,
});

typedef DiscoveryMetadataFilterData = ({
  TextEditingController genresController,
  Set<String> genres,
  Set<int> decades,
  Set<String> officialRatings,
  DiscoveryTriState watched,
  DiscoveryTriState favorite,
  List<String> availableGenres,
  List<int> availableDecades,
  List<String> availableRatings,
  void Function(String value, bool selected) onGenreChanged,
  void Function(int value, bool selected) onDecadeChanged,
  void Function(String value, bool selected) onOfficialRatingChanged,
  ValueChanged<DiscoveryTriState> onWatchedChanged,
  ValueChanged<DiscoveryTriState> onFavoriteChanged,
});

typedef DiscoveryPresetFilterData = ({
  TextEditingController nameController,
  Map<String, CatalogFilter> presets,
  ValueChanged<String> onApply,
  VoidCallback onSave,
});
