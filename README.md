# VilarVRC
Vilar's Shaders for VRChat

Most of the shaders here require specialized setup of some form. Below are setup instructions for each shader.

## EyeTrack
##### Configurable Eye Tracking

To set up your eyes for tracking with the VilarEyeTrack shader, you will need the origin of each eye object to be it's center. This process is simple in Blender:

---
![Eye Track Demo Gif](/Media/eyetrackdemo.jpg)

There are a few steps needed to get shader based eye tracking working on your Avatar. You will need to open Blender first and make each eye it's own object.

---
![Eye Mesh Instructions Image 2](/Media/eyemeshinstruct2.jpg)

Select your mesh. Press Tab to enter Edit Mode. Select your eye vertices (You will need to do this separately for each eye).

---
![Eye Mesh Instructions Image 3](/Media/eyemeshinstruct3.jpg)

Press Spacebar (Ctrl+Spacebar for Maya Bind Users) and type "Separate". Select "Mesh: Separate". Select "Selection".

---
![Eye Mesh Instructions Image 6](/Media/eyemeshinstruct6.jpg)

Press Tab to exit Edit Mode. Select your Armature, and press Tab to enter Edit Mode. Select the root of your eye bone.

---
![Eye Mesh Instructions Image 7](/Media/eyemeshinstruct7.jpg)

Press Spacebar and type "cursor". Select "View3D: Snap Cursor to Selected".

---
![Eye Mesh Instructions Image 8](/Media/eyemeshinstruct8.jpg)

Press Tab to exit Edit Mode. Select your eye object. Press Spacebar and type "origin". Select "Object: Set Origin". Select "Origin to 3D Cursor".

---
That should do the trick! Your eyes are now their own separate objects, ready to be animated by their shader!
Export your avatar and go back to Unity!

---
![Eye Track Demo Gif](/Media/materials.jpg)
Create a separate material for each eye. Set their shader to Vilar/EyeTrack.

---
![Eye Track Demo Gif](/Media/wizard.jpg)
Run the included setup wizard from VRChat SDK > Vilar's EyeTrack Setup. This will set the offset values for you, as well as autodetect orientation differences between Blender and Maya exports.


