Template lua project for playdate i suppose
1. Get the sdk


2. Add .luarc.json (root)
{
  "$schema": "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json",
  "diagnostics.globals": ["import"],
  "diagnostics.severity": { "duplicate-set-field": "Hint" },
  "format.defaultConfig": { "indent_style": "space", "indent_size": "4" },
  "runtime.builtin": { "io": "disable", "os": "disable", "package": "enable" },
  "runtime.nonstandardSymbol": ["+=", "-=", "*=", "/=", "//=", "%=", "<<=", ">>=", "&=", "|=", "^="],
  "runtime.version": "Lua 5.4",
  "workspace.preloadFileSize": 1000,
  "workspace.library": ["C:/Users/simon/playdate-luacats"]
}