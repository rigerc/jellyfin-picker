# Discovery feature boundary

`DiscoveryCubit` is the single application state source shared by future grid,
swipe, and shuffle presentations. Mode changes preserve the active filter,
presets, browsing position, decisions, and current reveal.

Binary decisions are intentional: liking or rejecting consumes a title from
undecided browsing. Rejected IDs are never eligible. When at least one like
exists, final reveals choose only liked IDs; otherwise they choose remaining
undecided IDs. Recent picks are excluded while another eligible choice exists.

Discovery persistence stores only a versioned, bounded continuity snapshot,
scoped by the stable server/user identity. It never stores catalog media,
posters, access tokens, or credentials. Corrupt or unsupported snapshots are
discarded safely, and clear removes only that discovery scope.
