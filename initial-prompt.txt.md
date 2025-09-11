I want to create an app that adds deliberate friction to user interaction to help people ‘calm down’ from endless scrolling/swiping.

This app is called ‘Slow Down’

It will be written in flutter and contain simple unit tests

The core functionality:
When the user opens the app, they are presented with a black screen with the words ‘slow down’ written in white in a sans serif font.

If the user swipes left, right up or down, the black screen with text will scroll away and be replaced by another black screen with the same text on it, as if it is a different screen. The speed of this scroll will be 100ms The text in this screen will have opacity reduced by 2%.

If the user swipes in any direction again, the same will happen, but the scroll speed will be increased by 100ms and the text opacity will be reduced by a further 2%.

In the bottom left hand corner of the screen will be a white burger menu button that is only 20% opacity. This will open a pop up with 1 button and one block of text in white on a black background with a grey border: 

‘Reset’ is a button, which will restart the scrolling process with a scroll speed of 100ms and 100% opacity for the white text and close the popup.

‘About’ is a small block of text with a copyright notice which says (c) Accelerated Intensity Ltd 2025 as well as a link to ‘https://accelerated-intensity.io'

As for clarification as necessary