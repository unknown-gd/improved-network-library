# Improved Network Library
A faster and more performance version of the Garry's Mod `net` library with additional cool features.

### Basic Changes
- `net.Receive` - has an additional third optional argument `string` "identifier" used for multiple receive callbacks.
- `net.Start` - automatically creates network strings on the server without using `util.AddNetworkString`.
- `net.StartX` - default `net.Start`.

## Where is Lua code?
Written in [Yuescript](https://github.com/pigpigyyy/Yuescript), compiled Lua code can be found in [releases](https://github.com/PrikolMen/improved-network-library/releases) and [lua branch](https://github.com/PrikolMen/improved-network-library/tree/lua), or you can compile it yourself using compiled [Yuescript Compiler](https://github.com/pigpigyyy/Yuescript/releases/latest).
