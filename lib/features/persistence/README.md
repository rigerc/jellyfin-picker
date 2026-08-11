# Persistence feature boundary

`SharedPreferencesDiscoveryStore` writes one versioned JSON blob per stable
server/user scope through `SharedPreferencesAsync`. The adapter is injected
behind `DiscoveryStore` and removes only its own scoped key; secure connection
storage remains isolated in the connection feature.
