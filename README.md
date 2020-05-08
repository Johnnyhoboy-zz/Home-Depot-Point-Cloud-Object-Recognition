# Home-Depot-Point-Cloud-Object-Recognition
Spring 2019 Intern project at Home Depot OrangeWorks Innovation Office in Atlanta, GA. <br> <br>
Developed with with ARKit 2.0, Swift 5, XCode 10.2, and tested on iPhone X running iOS 12+.

See the official project description and demo at: <br>
https://johnnyhoboy.github.io/portfolio-thd-ar.html

Alternative link for THD domain: <br>
https://pages.github.homedepot.com/orangeworks/projects/point-cloud-object-recognition/

## Overview

Status: Successful

If you were looking for a specific product, you would have a hard time searching for that product if you didn't know what it was called. This is especially true in the realm of the products we sell at THD.

AR frameworks such as ARKit are getting more powerful with every release. Last summer 2018, Apple announced ARKit 2 which provided new features such as persisting world maps, environment texturing, face tracking, and the USDZ file format. A prominent feature we wanted to focus and expand on was the new 3D Object Recognition, which is an improvement on top of its 2D image tracking and detection. 

Apple has provided a [3D scanning app](https://developer.apple.com/documentation/arkit/scanning_and_detecting_3d_objects) that allows the user to scan an object anywhere between the size of a ball to a chair. It does this by building a dense point cloud of what the camera sees and then exports it as an "ARObject" extension so developers can use it in Xcode. If we can match point clouds to specific objects, we can create an application where the camera can "detect" an object with your phone and overlay helpful information in AR.


## Problem/Goal

The goal of this project was to create various point cloud representations of Home Depot products. One point cloud use case was to see if the same point cloud can be used to represent two units of that object. For example, if you have two Ridgid power drills of the same model, can you create an ARObject of one of those drills and recognize the other drill with the same point cloud. 

Another use case was if we could detect objects, can we provide helpful information overlaid in AR? This can include the name and description of the object, the ability to bring it up the Home Depot website and "Add to Cart", or the convenience of loading up an online manual for the specific tool in case the owner lost the original. 

I have designed a custom iOS app for testing these features. This mobile app was developed on Xcode 10.2 with Swift 5 and ARKit 2.0 and tested on an iPhone X running iOS 12+.

## Demo and/or Images

Multiple objects around the OrangeWorks office were scanned through Apple's [3D scanning app](https://developer.apple.com/documentation/arkit/scanning_and_detecting_3d_objects), and then exported as ARObjects to a Xcode project. The scanning process requires the user to define a bounding box around their object in a well lit environment, scan all sides of it, and then it generates a point cloud model of that object. You can test the object at various angles to see how accurate and fast it is. Users have the ability to merge multiple scans for supposedly better detection if they desire. The objects scanned were a Ridgid 18v drill, a Esun 3D Filament box, a Titebond wood glue, two THD mugs, and two Xbox One controllers. 

The scanning process:
<br>
![scan 1](https://storage.googleapis.com/thdhb10631/bise95ebmitfghh2e4ag.PNG) 
![scan 2](https://storage.googleapis.com/thdhb10631/biseb3ebmitfghh2e4b0.PNG)
![scan 3](https://storage.googleapis.com/thdhb10631/bisebbmbmitfghh2e4bg.PNG)
<br>

However, not all objects are equal. Reflective or transparent surfaces have a tougher time to detect. Objects that have minimal detection features or are uniformly one color, such as the Xbox One controllers, are harder to detect at certain orientations as shown below:
<br>
![controller 1](https://storage.googleapis.com/thdhb10631/bit15l6bmitfghh2e4cg.PNG)
![controller 2](https://storage.googleapis.com/thdhb10631/bit15kubmitfghh2e4c0.PNG)
<br>

Once all objects were scanned in, I followed ARKit tutorials to learn how to develop an iOS AR app and overlay content in AR space upon detection of an ARObject. A spritekit scene with a picture, title, description, and a fake "Add to Cart" button were overlaid on top. Preliminary results showed that the Titebond wood glue and Esun 3D Filament box were detected within a second, most likely due to their colorful features and shape. The Xbox One controllers took more time to detect properly. The THD mugs were a bit reflective so detection only worked at a certain angles. Only one of the mugs were scanned into an ARObject, however the same point cloud model can be used to detect the other mug as shown below:
<br>
![box & glue](https://storage.googleapis.com/thdhb10631/bit18lmbmitfghh2e4e0.PNG)
![mug 1](https://storage.googleapis.com/thdhb10631/bit18lebmitfghh2e4dg.PNG)
![mug 2](https://storage.googleapis.com/thdhb10631/bit18lebmitfghh2e4d0.PNG)
<br>

Finally, for the Ridgid Drill, I wanted to explore if it was possible to overlay helpful web pages such as an online manual or the Home Depot product website. With a bit of tweaking space coordinates, it was possible. See the picture and demo video below:
<br>
![drill](https://storage.googleapis.com/thdhb10631/bit1b4ebmitfghh2e4eg.PNG)
<br>
### Watch the demo video [here](https://storage.googleapis.com/thdhb10631/bivne0587k78dceifpmg.MP4)
<br>

## Summary

Overall the whole project was a success thanks to the abundance of resources and tutorials available to learn ARKit 2. Credit links will be posted below in the extras section. I was able to successfully scan multiple objects and convert them into a point cloud model. Then I was able to create an iOS AR app that could detect those ARObject models on camera at a fast detection rate and overlay information in AR space. The same ARObject model of one object can also be used to detect another similar object. 

The entire code for this project can be found on [this repo](https://github.homedepot.com/Johnnyhoboy/Point-Cloud-Object-Recognition). Additionally, while learning ARKit I've placed multiple Easter eggs around the OrangeWorks office (scan the Technology Center plaque at the entrance or the Batman slapping Robin picture on the fridge!)

During the learning process I was able to figure out many limitations and caveats of ARKit 2.0's 3D Object Detection:

<ul>
<li>Scanning conditions are best in a well-lit environment with ample space to scan objects at all angles</li>
<li>Eligible objects must be between the size of a softball and a chair due to bounding box size</li>
<li>Having more distinguishing features such shape, color, outlines, etc will be easier to detect</li>
<li>Reflective or transparent surfaces are harder to detect at certain angles and lighting</li>
<li>ARObject file sizes are surprisingly small. All the objects scanned were between 600KB to 2.2MB. This means one iOS AR app can have the potential to store hundreds of ARObjects</li>
<li>Detected ARObjects will produce an ARAnchor in space that can trigger any custom event such as text, sound, video, etc. but will only happen once during a session</li>
<li>In order to have the app re-detect the same ARObject again, you must remove the corresponding ARAnchor. I've provided this functionality via a reset button that implements "removesAllAnchors" passed into the session's current run function</li>
<li>The renderer function can contain separate methods to detect when an anchor is added, did update, or will update</li>
<li>There is no isTracked() boolean for ARObjects as there are for ARImages, so live camera tracking to see if the ARObject is off-camera is currently not supported</li>
<li>You can only have an AR app run either an ARWorldTracking session or a ARImageTracking session</li>
<li>There are pros & cons of using ARWorldTracking (point cloud scanning, detect real world objects) over ARImageTracking (faster image detection, camera tracking, consumes less system resources)
<li>You can have simultaneous 2D image tracking and 3D object detection in the same AR app. To do this, run a ARWorldTracking session and set maximumNumberOfTrackedImages equal to positive number. Default is 0, but having more takes more system resources</li>
<li>You can attach 3D spacial audio to objects and hear the difference as you walk around. Mono sound files work best, however it seems there is no native spacial audio support for MP4 videos such as AVPlayer</li>
<li>Finally, ARObjects are simple sparse 3D point cloud models. They are NOT 3D texture/photogrammetry scans or USDZ files of an object, and aside from using it in ARKit, there seems to be no other use case for them.</li>
</ul>


## Future Work

As augmented reality frameworks and smartphones get more powerful with every release, I can see a future where AR will be a ubiquitous technology that's used more in our current mobile applications. Imagine having a database of ARObjects that are pre-scanned and having an implementation in the Home Depot mobile app that allows the user to use the camera to detect a THD product and instantly display helpful information. It can be product information, model numbers, ability to product to cart, online manuals, warranties, etc. With ARObjects being such small file sizes, we have the potential to store hundreds of pre-scanned products in a mobile app. 

This project could also be extended to be used for wearable mixed reality headsets as well. Imagine a worker needing to build a component from parts. The headset could provide helpful instructions and continuously monitor specific objects needed at each step of the process. Object point clouds can be detected to make sure it is the right part for the installation process.


## Helpful Links

Below are various links to resources that helped me learn iOS development, ARKit documentation, and inspirational projects by talented developers:

### Introduction to iOS & ARKit 2.0

[Why You Should Be Freaking Out Over ARKit 2](https://medium.com/maestral-solutions/why-you-should-be-freaking-out-over-arkit-2-53f2ba098083)

[Learn ARKit with Swift - Udacity](https://classroom.udacity.com/courses/ud116)

[An Introduction to ARKit 2 - Object Scanning](https://blog.usejournal.com/an-introduction-to-arkit-2-object-scanning-68963b9be43a)

[Detecting 3D Objects using ARKit 2.0](https://www.yudiz.com/detecting-3d-objects-using-arkit-2-0/)

[ARKit 2 Tutorial: Create an AR Shopping Experience](https://www.youtube.com/watch?v=FEqBW3cKF2k)

[Building a Museum App with ARKit 2](https://www.raywenderlich.com/6957-building-a-museum-app-with-arkit-2)

### Documentation 

[Apple - ARKit](https://developer.apple.com/documentation/arkit)

[Apple - Building Your First AR Experience](https://developer.apple.com/documentation/arkit/building_your_first_ar_experience)

[Apple - Detecting Images in an AR Experience](https://developer.apple.com/documentation/arkit/detecting_images_in_an_ar_experience)

[Apple - Creating an Immersive AR Experience with Audio](https://developer.apple.com/documentation/arkit/creating_an_immersive_ar_experience_with_audio)

[Apple - Understanding World Tracking in ARKit](https://developer.apple.com/documentation/arkit/understanding_world_tracking_in_arkit)

[Apple - 3D scanning app](https://developer.apple.com/documentation/arkit/scanning_and_detecting_3d_objects)

### Inspirational Prototypes

[3D Scan and Detect using Unity and Xcode](https://pages.github.homedepot.com/orangeworks/projects/3d-scan-and-detect-unity.md/3d-scan-and-detect-unity/)

[What I Learned Making 5 ARKit Prototypes](https://medium.com/@nathangitter/what-i-learned-making-five-arkit-prototypes-7a30c0cd3956)

[Awesome ARKit - GitHub curated list of projects](https://github.com/olucurious/Awesome-ARKit)

[AR Business Card Concept](https://www.youtube.com/watch?v=Jq98OEXJSr8)

[Using ARKit and Image Tracking to Augment a Postcard](https://www.viget.com/articles/using-arkit-and-image-tracking/)

[AR Restaurant Menu Concept made with ARKit](https://www.youtube.com/watch?v=E2K052WwzpM)
