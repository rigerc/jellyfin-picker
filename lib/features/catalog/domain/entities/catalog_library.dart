final class CatalogLibrary {
  const CatalogLibrary({
    required this.id,
    required this.name,
    required this.collectionType,
  });

  final String id;
  final String name;
  final String collectionType;

  @override
  bool operator ==(Object other) =>
      other is CatalogLibrary &&
      other.id == id &&
      other.name == name &&
      other.collectionType == collectionType;

  @override
  int get hashCode => Object.hash(id, name, collectionType);
}
