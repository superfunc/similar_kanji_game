A simple little game for drilling kanji that you frequently mix up.

## Running the game

The game requires love2d (https://love2d.org) to run, 
see https://love2d.org/wiki/Getting_Started for instructions on how to run for your platform.

## Modification

Users can modify a few things to customize their experience:

- Fonts: if a user adds a ttf font into the fonts/ dir, the settings menu will
allow them to select that as the font used for kanji + answer display.
- Definitions: the user can modify `joyo_kanji.lua` so long as the formatting stays in tact (note 
that definitions are ; separated).
- Groupings: the user can add, remove or modify "similar-kanji" groups from `similar_kanji.lua`, again, so long as the formatting as a proper lua table stays in place.

## Attribution

### Data

The data was pulled from jisho.org's API, and the WaniKani data from https://wkstats.org

### Sounds

The sounds were provided from https://twitter.com/kennynl 's free asset pack.

### Fonts

The fonts are released under the Open Font license, links to their google fonts pages are below

### Art

The images were made by https://twitter.com/samfilstrup, if you like them, please go support the artist!
