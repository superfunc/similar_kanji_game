A simple little game for drilling kanji that you frequently mix up.

![](./data/start/start_0.png)

## Running the game

The game requires love2d (https://love2d.org) to run, 
see https://love2d.org/wiki/Getting_Started for instructions on how to run for your platform.

## Modification

Users can modify a few things to customize their experience:

- Settings: sound can be disabled, the number of definitions shown can be increased (1-3), and the user can set their WaniKani level, so no data above their level will be used.
- Fonts: if a user adds a ttf font into the fonts/ dir, the settings menu will
allow them to select that as the font used for kanji + answer display.
- Definitions: the user can modify `joyo_kanji.lua` so long as the formatting stays in tact (note 
that definitions are ; separated).
- Groupings: the user can add, remove or modify "similar-kanji" groups from `similar_kanji.lua`, again, so long as the formatting as a proper lua table stays in place, and that the group size is > 1.

## Attribution

### Data

The data was pulled from https://jisho.org 's API, and the WaniKani data from https://wkstats.com

### Sounds

The sounds were provided from https://twitter.com/kennynl 's free asset pack.

### Fonts

The fonts are released under the Open Font license, links to their google fonts pages are below

- Sniglet: https://fonts.google.com/specimen/Sniglet?thickness=9#standard-styles
- Sue Ellen Francisco: https://fonts.google.com/specimen/Sue+Ellen+Francisco?category=Handwriting
- Zen Kurenaido: https://fonts.google.com/specimen/Zen+Kurenaido?query=zen&subset=japanese

### Art

The images were made by https://twitter.com/samfilstrup, if you like them, please go support the artist!

## Known Issues

- It looks a bit oversized on retina displays
