# litevi

Start of vi clone bindings for the lite text editor (rxi/lite; only tested with rxi/lite-xl).

Based on https://raw.githubusercontent.com/a327ex/lite-plugins/master/plugins/modalediting.lua

For an introduction to that work, see https://github.com/a327ex/blog/issues/56


## TODO

Very much.

Current personal list of annoyances:

- fix next/prev word so it acts like vi (fix I to start of text at same time)
- consider what to do with escape in autocomplete box...
- default to modal when switching files (?)
- replace shift usage with v/V. Once done:
  - J (needed at the moment for selection)
- I takes one to start of line, not start of text
- add repeats (numbers) and subsequent movements (i.e. d?, y?)
- d can't delete last line in file
- D delete to end of line
- p starts newlines _all the time_. Should just use what's in buffer (and complete/multiline
  cuts should include an initial newline to signal this... maybe - should see what vim puts in buffer)
- p leaves you at end of line, which is annoying when line is greater than screen width


