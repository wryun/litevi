# litevi

Start of vi clone bindings for the lite text editor (rxi/lite; only tested with rxi/lite-xl).

Based on https://raw.githubusercontent.com/a327ex/lite-plugins/master/plugins/modalediting.lua

For an introduction to that work, see https://github.com/a327ex/blog/issues/56


## TODO

Very much.

Current personal list of annoyances:

- fix next/prev word (currently completely broken, since it relies on removed functionality)
- default to modal when switching files (?)
- replace shift usage with v
- I takes one to start of line, not start of text
- add repeats (numbers) and subsequent movements (i.e. d?, y?)
- reinstate auto-indent fixes
- J
- G
- d can't delete last line in file
- D delete to end of line
- p doesn't properly start a new line (bad interaction with auto-indent?)
- J doesn't work
- p leaves you at end of line, which is annoying when line is greater than screen width


