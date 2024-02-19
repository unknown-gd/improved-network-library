# Improved Network Library
A faster and more performance version of the Garry's Mod `net` library with additional cool features.

### Basic Changes
- GM:IncomingNetworkMessage( `string` networkString, `number` length, `Player/NULL` ply ) - if return here `false` then callbacks will not be called. **[SERVER/CLIENT]**
- `net.Receive` - has an additional third optional argument `string` "identifier" used for multiple receive callbacks. **[SERVER/CLIENT]**
- `net.Start` - automatically creates network strings on the server without using `util.AddNetworkString`. **[SERVER]**
- `net.StartX` - default `net.Start`. **[SERVER]**

## Where is Lua code?
Written in [Yuescript](https://github.com/pigpigyyy/Yuescript), compiled Lua code can be found in [releases](https://github.com/PrikolMen/improved-network-library/releases) and [lua branch](https://github.com/PrikolMen/improved-network-library/tree/lua), or you can compile it yourself using compiled [Yuescript Compiler](https://github.com/pigpigyyy/Yuescript/releases/latest).
