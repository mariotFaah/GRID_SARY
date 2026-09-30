# Grid Art - User Guide

Version 1.0

## 1. What is Grid Art?

Grid Art is an app that draws a grid on top of your photos so that you can reproduce them by hand on paper. You choose the size of your sheet, the size of the squares, and the look of the lines, then you place one or more images on the page and save the result as a PNG file that you can print or keep on your phone.

The technique is simple: draw the same grid lightly on your paper, then copy the photo one square at a time. Because every square is small, it is much easier to get proportions and positions right.

The app works fully offline. Your images are never uploaded anywhere and stay on your device.

Note: the app interface is currently in French. This guide gives the French label first, followed by its English meaning in parentheses.

## 2. Installation

### Android

1. Download the APK file from the link you were given. If you are not sure which file to choose, take the file named `arm64-v8a`. It works on almost all recent phones. If your phone says the app is not compatible, try the `armeabi-v7a` file, which is made for older 32-bit phones.
2. Open the downloaded file.
3. Android may ask you to allow installation from this source (for example, from your browser or your file manager). Accept this for the installation.
4. Google Play Protect may show a warning because the app does not come from the Play Store. Choose "Install anyway".
5. Open Grid Art from your app list.

### Linux (desktop)

The Linux version runs as a normal desktop window. Start the application from the folder where it was built or installed. The window is resizable, and the settings menu stays open next to the page so that you can see your changes immediately.

## 3. Quick start

1. Open the menu with the three-line icon (hamburger) in the top-left corner.
2. In "Format de la page" (Page format), choose a paper size such as A4.
3. In "Grille" (Grid), enter the distance between lines, for example 1 cm.
4. In "Calques d'images" (Image layers), tap "Ajouter des images" (Add images) and pick a photo.
5. Drag the image on the page to position it, and pinch to resize it.
6. Tap the save icon in the top bar to export a PNG.

## 4. The main screen

The main screen shows your page in the center, exactly as it will be exported. There are two controls in the top bar:

- The menu icon (three lines) on the left opens the settings panel.
- The save icon on the right exports your page as a PNG.

The settings panel is called "Réglages" (Settings). It is organized in three collapsible sections: Page format, Grid, and Image layers. Tap a section title to open or close it. Close the panel with the cross at its top, by tapping outside of it, or by swiping it to the left, so that you can see the whole page while you move your images.

## 5. Page format

Section "Format de la page" (Page format).

### Standard sizes

Tap one of the chips to choose a paper size. The sizes are in centimeters.

| Format | Width x Height (cm) |
|--------|---------------------|
| A0 | 84.1 x 118.9 |
| A1 | 59.4 x 84.1 |
| A2 | 42.0 x 59.4 |
| A3 | 29.7 x 42.0 |
| A4 | 21.0 x 29.7 |
| A5 | 14.8 x 21.0 |
| A6 | 10.5 x 14.8 |

### Orientation

Use the switch "Portrait" / "Paysage" (Landscape) to rotate the page. The width and height values are swapped automatically.

### Custom size

Type your own values in the "Largeur" (Width) and "Hauteur" (Height) fields, in centimeters. You can use a dot or a comma as decimal separator. As soon as you type a value, the format changes to "Personnalisé" (Custom). Values must be greater than zero.

## 6. Grid

Section "Grille" (Grid).

### Distance between lines

The field "Distance entre les lignes" (Distance between lines) sets the size of each square, in centimeters. A value of 1 gives 1 cm by 1 cm squares. Choose the same spacing that you will draw on your paper.

If the squares become too small to be displayed on screen (for example a very small spacing on a large page), the grid is hidden in the preview. Increase the spacing to see it again.

### Diagonals (X)

Tick "Diagonales en X" (Diagonals in X) to draw both diagonals inside every square. This is useful to find the center of each square and to check angles while drawing. The diagonals use the same color, opacity and thickness as the grid lines. They are drawn only in complete squares. If the page size is not an exact multiple of your spacing, the partial squares along the right and bottom edges do not get diagonals.

### Color

Choose a line color among eight colors: black, white, red, blue, green, orange, purple and grey. The selected color has a thicker outline. Pick a color that contrasts with your photo, for example white on a dark picture.

### Opacity

The "Opacité" (Opacity) slider goes from 5 % to 100 %. A lower value makes the grid more discreet so that the photo stays readable.

### Thickness

The "Épaisseur" (Thickness) slider sets how thick the lines are, from thin to thick. The thickness stays proportional to the page, so the exported image looks like the preview.

## 7. Image layers

Section "Calques d'images" (Image layers). You can place several images on the same page, each one on its own layer.

### Adding images

Tap "Ajouter des images" (Add images) and choose one or several pictures. The first image fills the page. Additional images arrive at half size, placed alternately on the left and on the right, so they do not hide each other right away. You can add more images at any time.

### Selecting a layer

The list shows the top layer first. Tap a layer to select it. The selected layer is highlighted and is the one that reacts to your gestures and sliders.

### Moving and resizing

With a layer selected:

- Drag on the page with a finger (or the mouse) to move it.
- Pinch with two fingers to resize it. On a computer, use the mouse wheel.
- Use the "Taille" (Size) slider to set the size precisely, from 5 % to 500 %.

### Layer opacity

The "Opacité du calque" (Layer opacity) slider makes the selected image more or less transparent. This is useful when two images overlap.

### Layer controls

Each line of the list has four buttons:

- The eye shows or hides the layer. A hidden layer is not exported.
- The up arrow brings the layer in front of the others.
- The down arrow sends the layer behind the others.
- The bin deletes the layer.

The button "Recentrer le calque" (Recenter the layer) puts the selected image back at its original position and size.

The grid is always drawn above all the images, so it is never hidden by a layer.

## 8. Saving your work

Tap the save icon in the top bar, or the button "Enregistrer en PNG" (Save as PNG) at the bottom of the settings panel.

- On Android, the image is saved in your photo gallery. The first time, Android may ask for permission to save photos. Accept it.
- On Linux, the image is saved in your Downloads folder. If that folder is not available, the Documents folder is used. The exact file path is shown at the bottom of the screen after saving.

Only the page is exported, without the menu or any interface element. The image quality is about 300 dpi. For very large formats such as A0 or A1, the longest side is limited to 6000 pixels to avoid running out of memory, so the resolution is a little lower on these sizes. Files are named `grille_` followed by a number.

## 9. Using the result for drawing

1. Choose the format that matches your paper, for example A3 if you draw on A3.
2. Set the same square size that you will draw with a ruler, for example 2 cm.
3. Place your photo so that it fills the page the way you want.
4. Save the PNG. If you want to print it, print at 100 % scale (no "fit to page") so that the squares keep their real size.
5. On your paper, lightly draw the same grid with a pencil and ruler, then copy the content of each square one after another. Erase the grid lines at the end.

If you only want to draw on paper while looking at your phone, you can also keep the image on screen and skip printing.

## 10. Troubleshooting

**The app does not install.**
Make sure you allowed installation from unknown sources. If the phone says the app is not compatible, download the other APK file (`armeabi-v7a` instead of `arm64-v8a`).

**A warning says the app may be harmful.**
This is the standard Play Protect message for apps installed outside the Play Store. Choose "Install anyway".

**The image does not load.**
Try another picture. Very large or unusual image files can fail to load. Also check that the app is allowed to access your photos.

**I cannot save the image on Android.**
Open the Android settings, go to the app permissions for Grid Art, and allow access to photos or storage. Then try again.

**The grid is not visible.**
Increase the distance between lines, increase the opacity, or choose a color that contrasts with your image.

**I cannot move the image.**
Select a layer in the list first. Gestures only apply to the selected layer.

**The exported image looks different from the preview.**
Only the page area is exported. Anything outside the page, for example a part of an image that was moved off the edge, is cut.

## 11. Current limitations

- Your layout is not saved when you close the app. Export a PNG before leaving.
- There is no undo button.
- Images cannot be cropped or rotated. They can only be moved and resized.
- Diagonals are drawn only in complete squares.

## 12. Privacy

Grid Art does not need an internet connection and does not send your images or any data anywhere. Everything is processed on your device.

## 13. Contact and feedback

If you find a bug or have an idea to improve Grid Art, contact the developer through the link or the address you received with the app.
