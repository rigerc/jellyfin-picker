# Agent Learning Log

This file is auto-maintained by AI agents as a self-improving mistake log.
Each iteration captures a concrete mistake, the pattern to avoid, and the better approach.
Do not edit past entries; append only.

---

## Agent Learning Log: Iteration #1

**Date**: 2026-08-14 | **Task**: Add safe Jellyfin trailers and correct discovery filters
**Signal**: Pre-write violation

### ❌ Mistake Made
The first `_trailers` parser draft in `jellyfin_catalog_repository.dart` force-unwrapped nullable trailer URIs after filtering, violating the active Dart null-safety rule.

### 🚫 Pattern to Avoid
- **No force unwraps in parsing pipelines**: Validation in an earlier collection stage does not give Dart sound promotion in later closures.

### ✅ Better Approach
Parse each untrusted trailer object through a typed nullable helper, return `null` for invalid values, and use `whereType<CatalogTrailer>()` to retain only validated results.

---

## Agent Learning Log: Iteration #2

**Date**: 2026-08-14 | **Task**: Add safe Jellyfin trailers and correct discovery filters
**Signal**: Pre-write violation

### ❌ Mistake Made
The first trailer-button label expression in `discovery_details_sheet.dart` force-unwrapped `trailer.name` after checking a derived nullable expression.

### 🚫 Pattern to Avoid
- **No repeated nullable property reads in display ternaries**: they encourage unnecessary force unwraps and obscure normalization.

### ✅ Better Approach
Normalize the nullable display value once in a helper and return the localized fallback when it is null or empty.

---

## Agent Learning Log: Iteration #3

**Date**: 2026-08-14 | **Task**: Add safe Jellyfin trailers and correct discovery filters
**Signal**: Session retrospective

### ❌ Mistake Made
The formatting command passed `AGENTS_LEARNING.md` to `dart format` alongside Dart source directories, producing an avoidable parser failure after the intended Dart files were formatted.

### 🚫 Pattern to Avoid
- **No mixed-language formatter targets**: Dart tooling treats Markdown as invalid source and turns a clean formatting step into a failing command.

### ✅ Better Approach
Pass only Dart files or Dart source directories to `dart format`; validate Markdown separately when a Markdown formatter is configured.
