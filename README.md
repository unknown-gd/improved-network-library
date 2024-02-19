# Improved Network Library
A faster and more performance version of the Garry's Mod `net` library with additional cool features.

### Basic Changes
- `net.Receive` - has an additional third optional argument `string` "identifier" used for multiple receive callbacks.
- `net.Start` - automatically creates network strings on the server without using `util.AddNetworkString`.
- `net.StartX` - default `net.Start`.
