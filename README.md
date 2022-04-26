> ⚠️ bugs will get fixed, feel free to file them or submit PRs for them, 
> but packaging, feature requests, and feature request PRs I likely won't have time for.

A simple little game for drilling kanji that you frequently mix up.

readme contents
- screenshots
- running the game
- user customization
- attribution


## Screenshots

<img width="1218" alt="make" src="https://user-images.githubusercontent.com/1583002/165000036-6d382c1b-06dd-4475-b93a-83b0977ab3db.png">

<img width="1219" alt="miss" src="https://user-images.githubusercontent.com/1583002/165000039-26bad7ff-e39a-47dd-86e7-8d65f7f391f0.png">

<img width="1222" alt="end" src="https://user-images.githubusercontent.com/1583002/165000042-ee5652c6-7583-4cac-a4a4-951ad148667a.png">

  
## Running the game

The game requires love2d (https://love2d.org) to run
1. Install love2d
2. Download the zip of this repository & unzip
<img width="423" alt="Screen Shot 2022-04-24 at 4 12 35 PM" src="https://user-images.githubusercontent.com/1583002/165000619-be7cfbfd-0092-4024-8203-13eeb64f65c3.png">
3. Run the command for your platform below



Windows (use CMD application):
```
"C:\Program Files\LOVE\love.exe" "C:\<path-to-game>\similar_kanji"
```

linux (from a terminal)
```
love <path-to-unzipped-dir>/similar_kanji
```

macOS (from a terminal)
```
open -n -a love <path-to-unzipped-dir>/similar_kanji
```

It isn't bundled as an exe so users can freely modify the input data as they so chose, see the
_modification_ section below for details.

## How to play

Choose play > choose a mode (onyomi, kunyomi or meaning).

**In Game** 
- In the center, a kanji is displayed, on each side is a potential answer,
based on the `similar_kanji.lua` file. Choose an answer by inputting left or
right on the keyboard. The score recieved for a correct answer is multiplied
by the amount of time remaining on the time bar (pink). 

- Press escape to pause in game.

**Menus**

- Directional buttons to navigate
- Enter to confirm

**Post Game**

- A file `troubled_kanji.txt` will be saved in the game's corresponding save dir, described here
https://love2d.org/wiki/love.filesystem. This will contain the full list of kanji you've gotten wrong, 
it's purpose is simply so users can grab and paste the kanji into something else like a text document
if they wanted.

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
