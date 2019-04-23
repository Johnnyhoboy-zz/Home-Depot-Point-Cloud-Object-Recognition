// Custom AR prototype made for Home Depot Innovation Center
// Developed for Iphone X with Swift 5 on iOS 12
// John Ho - Software Development Intern, Spring 2019

import UIKit
import SceneKit
import ARKit
import CoreMedia

struct TrackedObject {
    var name : String
    var node : SCNNode?
}

class ViewController: UIViewController {

    /// A serial queue for thread safety when modifying SceneKit's scene graph.
    let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
    
    //MARK: Properties
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var restartExperienceButton: UIButton!
    
    // Add configuration variables here:
    private var imageConfiguration: ARImageTrackingConfiguration?
    private var worldConfiguration: ARWorldTrackingConfiguration?
    
    // Video player
    var avPlayer: AVPlayer?
    
    // Arrays for tracked ARObjects and their nodes, currently only images are used
    var trackedImages : [TrackedObject] = [ TrackedObject(name: "batman", node: nil), TrackedObject(name: "john", node: nil), TrackedObject(name: "techCenter", node: nil), TrackedObject(name: "xoxo", node: nil) ]

    var trackedObjects : [TrackedObject] = [ TrackedObject(name: "Esun 3D Filament", node: nil), TrackedObject(name: "Ridgid Drill", node: nil), TrackedObject(name: "THD Mug", node: nil), TrackedObject(name: "Wood Glue", node: nil), TrackedObject(name: "Xbox One Controller", node: nil) ]
    
    // Audio sounds on detect
    lazy var dingAudio: SCNAudioSource = {
        let source = SCNAudioSource(fileNamed: "ding.wav")!
        source.loops = false
        source.load()
        return source
    }()
    lazy var pikaAudio: SCNAudioSource = {
        let source = SCNAudioSource(fileNamed: "pika.wav")!
        source.loops = false
        source.load()
        return source
    }()
    lazy var slapAudio: SCNAudioSource = {
        let source = SCNAudioSource(fileNamed: "slap.wav")!
        source.loops = true
        source.isPositional = true
        source.shouldStream = false 
        source.load()
        return source
    }()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true {
        didSet { restartExperienceButton.isEnabled = isRestartAvailable }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        
        // Uncomment to show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Enable environment-based lighting
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/GameScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Prevent the screen from being dimmed to avoid interuppting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupObjectDetection()
        
        if let configuration = worldConfiguration {
            // Show AR cloud points
            sceneView.debugOptions = .showFeaturePoints
            // Run the view's session
            sceneView.session.run(configuration, options: ARSession.RunOptions(arrayLiteral: [.resetTracking, .removeExistingAnchors]))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Configuration functions to fill out
    // This is for image tracking only mode
    private func setupImageDetection() {
        imageConfiguration = ARImageTrackingConfiguration()
        
        guard let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Images", bundle: nil) else {
                fatalError("Missing expected asset catalog resources.")
        }
        imageConfiguration?.trackingImages = referenceImages
    }
    
    // This is for both object and image tracking mode
    private func setupObjectDetection() {
        worldConfiguration = ARWorldTrackingConfiguration()
        
        guard let referenceObjects = ARReferenceObject.referenceObjects(
            inGroupNamed: "ARObjects", bundle: nil) else {
                fatalError("Missing expected asset catalog resources.")
        }
        
        worldConfiguration?.detectionObjects = referenceObjects

        guard let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "ARPictures", bundle: nil) else {
                fatalError("Missing expected asset catalog resources.")
        }
        
        // In order for images to be tracked alongside objects, must set # of images
        // Note detecting more images = more device resources
        worldConfiguration?.detectionImages = referenceImages
        worldConfiguration?.maximumNumberOfTrackedImages = 4
        
    }
    
    // Reset tracking whenever the reset button is pressed
    private func resetTracking() {
        setupObjectDetection()
        if let configuration = worldConfiguration {
            print("Reset")
            
            DispatchQueue.main.async {
                self.avPlayer?.pause()
                //self.avPlayerLayer!.removeFromSuperlayer()
            }
            
            // Search the corresponding node for the ar image anchor
            for (index, trackedObject) in trackedImages.enumerated(){
                trackedObject.node?.isHidden = true // Hide or delete content
                trackedObject.node?.removeFromParentNode()
            }

            // Show AR cloud points
            sceneView.debugOptions = .showFeaturePoints
            // Run the view's session
            sceneView.session.run(configuration, options: [ARSession.RunOptions.removeExistingAnchors, ARSession.RunOptions.resetTracking])
        }
        // Reset any placed object or live preview
    }
    
    // MARK: - IBActions
    @IBAction private func restartExperience(_ sender: UIButton) {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        resetTracking()
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.isRestartAvailable = true
        }
    }
    
} //UIViewController


// MARK: - Session errors
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard
            let error = error as? ARError,
            let code = ARError.Code(rawValue: error.errorCode)
            else { return }
        instructionLabel.isHidden = false
        switch code {
        case .cameraUnauthorized:
            instructionLabel.text = "Camera tracking is not available. Please check your camera permissions."
        default:
            instructionLabel.text = "Error starting ARKit. Please fix the app and relaunch."
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(let reason):
            instructionLabel.isHidden = false
            switch reason {
            case .excessiveMotion:
                instructionLabel.text = "Too much motion! Slow down."
            case .initializing, .relocalizing:
                instructionLabel.text = "ARKit is doing it's thing. Move around slowly for a bit while it warms up."
            case .insufficientFeatures:
                instructionLabel.text = "Not enough features detected, try moving around a bit more or turning on the lights."
            }
        case .normal:
            instructionLabel.text = "Point the camera at a registered object or image."
        case .notAvailable:
            instructionLabel.isHidden = false
            instructionLabel.text = "Camera tracking is not available."
        }
    }
}

// MARK: - Handle object detection
extension ViewController: ARSCNViewDelegate {
    
    // Called when any node has been added to the anchor
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async { self.instructionLabel.isHidden = true }
        
        // Determine if image or object is detected
        if let imageAnchor = anchor as? ARImageAnchor {
            
            handleFoundImage(imageAnchor, node)
            
        } else
        if let objectAnchor = anchor as? ARObjectAnchor {
            handleFoundObject(objectAnchor, node)
        }
    } //renderer didAdd
    
    
    private func handleFoundImage(_ imageAnchor: ARImageAnchor, _ node: SCNNode) {
        
        let name = imageAnchor.referenceImage.name!
        print("You found a \(name) image")
        
        DispatchQueue.main.async {
            self.instructionLabel.isHidden = false
            self.instructionLabel.text = "You've detected: " + name}
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {             self.instructionLabel.text = "Point the camera at a registered object or image." })
        
        let size = imageAnchor.referenceImage.physicalSize
        
        if name == "techCenter" {
            if let videoURL = Bundle.main.url(forResource: "orangeworks", withExtension: "mp4"){
                
                if let videoNode = makeVideo(size: size, fromURL: videoURL) {
                    node.addChildNode(videoNode)
                    node.opacity = 1
                    
                    // Add the node to the tracked images
                    for (index, trackedObject) in trackedImages.enumerated(){
                        if(trackedObject.name == name){
                            trackedImages[index].node = videoNode
                        }
                    }
                }
            }
        } else if name == "john" {
            let plane = SCNPlane(width: CGFloat(imageAnchor.referenceImage.physicalSize.width), height: CGFloat(imageAnchor.referenceImage.physicalSize.height))
            plane.firstMaterial?.diffuse.contents = UIImage(named: "pikachu.png")
            
            let planeNode = SCNNode(geometry: plane)
            // SCNPlane is vertically oritented in local coordinate space but ARImageAnchor assumes image is horizontal in local space, so rotate plane to match
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
            node.addAudioPlayer(SCNAudioPlayer(source: pikaAudio))

            // Add the node to the tracked images
            for (index, trackedObject) in trackedImages.enumerated(){
                if(trackedObject.name == name){
                    trackedImages[index].node = planeNode
                }
            }
        } else if name == "batman" {
            if let videoURL = Bundle.main.url(forResource: "slap", withExtension: "mp4"){
                
                if let videoNode = makeVideo(size: size, fromURL: videoURL) {
                    node.addChildNode(videoNode)
                    node.opacity = 1
                node.addAudioPlayer(SCNAudioPlayer(source: slapAudio))
                    
                    // Add the node to the tracked images
                    for (index, trackedObject) in trackedImages.enumerated(){
                        if(trackedObject.name == name){
                            trackedImages[index].node = videoNode
                        }
                    }
                }
            }
        } else if name == "18vDrill" {
            // Test case for generating webview & sceneview for an image
            generateViews(imageAnchor, node)
            
        } //if-else
    } //HandleFoundImage
    
    // Generate views for an image detection
    private func generateViews (_ imageAnchor: ARImageAnchor, _ node: SCNNode) {
        
        updateQueue.async {
            let physicalWidth = imageAnchor.referenceImage.physicalSize.width
            let physicalHeight = imageAnchor.referenceImage.physicalSize.height
            
            // Create a plane geometry to visualize the initial position of the detected image
            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
            mainPlane.firstMaterial?.colorBufferWriteMask = .alpha
            
            // Create a SceneKit root node with the plane geometry to attach to the scene graph
            // This node will hold the virtual UI in place
            let mainNode = SCNNode(geometry: mainPlane)
            mainNode.eulerAngles.x = -.pi / 2
            mainNode.renderingOrder = -1
            mainNode.opacity = 1
            
            // Add the plane visualization to the scene
            node.addChildNode(mainNode)
            
            // Perform a quick animation to visualize the plane on which the image was detected.
            // We want to let our users know that the app is responding to the tracked image.
            self.highlightDetection(on: mainNode, width: physicalWidth, height: physicalHeight, completionHandler: {
                
                // Introduce virtual content
                self.displayDetailView(on: mainNode, xOffset: physicalWidth, yOffset: physicalHeight)
                
                // Animate the WebView to the right
                self.displayWebView(on: mainNode, xOffset: physicalWidth, yOffset: physicalHeight)
                
            })
        }
        
    } //generateViews image anchor
    
    // Show a video running in AR
    private func makeVideo(size: CGSize, fromURL url: URL) -> SCNNode? {
        
        // 2
        let avPlayerItem = AVPlayerItem(url: url)
        self.avPlayer = AVPlayer(playerItem: avPlayerItem)
        self.avPlayer?.play()
        // 3
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: nil) { notification in
                self.avPlayer!.seek(to: .zero)
                self.avPlayer!.play()
        }
        // 4
        let avMaterial = SCNMaterial()
        avMaterial.diffuse.contents = avPlayer
        // 5
        let videoPlane = SCNPlane(width: size.width, height: size.height)
        videoPlane.materials = [avMaterial]
        // 6
        let videoNode = SCNNode(geometry: videoPlane)
        videoNode.eulerAngles.x = -.pi / 2
        return videoNode
    } //makeVideo
    
    
    private func handleFoundObject(_ objectAnchor: ARObjectAnchor, _ node: SCNNode) {
        
        let name = objectAnchor.referenceObject.name!
        
        let plane = SCNPlane(width: CGFloat(objectAnchor.referenceObject.extent.x * 0.8), height: CGFloat(objectAnchor.referenceObject.extent.y * 0.5))
            
        plane.cornerRadius = plane.width / 8
            
        print("You found a \(name) object")
        DispatchQueue.main.async {
        self.instructionLabel.isHidden = false
            self.instructionLabel.text = "You've detected: " + name}
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            self.instructionLabel.text = "Point the camera at a registered object or image."
        })
            
        if name == "Ridgid Drill" {
            // Converted generate views into 3D object space
            generateViews(objectAnchor, node)
        } else {
            // Test cases for various scanned objects
            if name == "THD Mug" {
                    let spriteKitScene = SKScene(fileNamed: "CupInfo")
                    plane.firstMaterial?.diffuse.contents = spriteKitScene
            } else if name == "Wood Glue" {
                    let spriteKitScene = SKScene(fileNamed: "GlueInfo")
                    plane.firstMaterial?.diffuse.contents = spriteKitScene
            } else if name == "Xbox One Controller" {
                    let spriteKitScene = SKScene(fileNamed: "XboxInfo")
                    plane.firstMaterial?.diffuse.contents = spriteKitScene
            } else if name == "Esun 3D Filament" {
                    let spriteKitScene = SKScene(fileNamed: "FilamentInfo")
                    plane.firstMaterial?.diffuse.contents = spriteKitScene
            } else {
                    let spriteKitScene = SKScene(fileNamed: "DefaultInfo")
                    plane.firstMaterial?.diffuse.contents = spriteKitScene
            }
        
            // Determine plane location
            plane.firstMaterial?.isDoubleSided = true
            plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, objectAnchor.referenceObject.center.y + 0.10, objectAnchor.referenceObject.center.z)
        
            // Orientate plane so that it always faces user
            let billboardConstraints = SCNBillboardConstraint()
            planeNode.constraints = [billboardConstraints]
            node.addChildNode(planeNode)
            node.addAudioPlayer(SCNAudioPlayer(source: dingAudio))
        
            // Add the node to the tracked images
            for (index, trackedObject) in trackedObjects.enumerated(){
                if(trackedObject.name == name){
                    trackedImages[index].node = node
                }
            }
        } // else
        
    } //handleFoundObject
    
    // Overloaded function for an ARObjectAnchor
    private func generateViews (_ objectAnchor: ARObjectAnchor, _ node: SCNNode) {
        
        updateQueue.async {
            
            let physicalHeight = CGFloat(objectAnchor.referenceObject.extent.y)
            let physicalWidth = CGFloat(objectAnchor.referenceObject.extent.x)
            
            // Determine plane location
            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
            //mainPlane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
            mainPlane.firstMaterial?.colorBufferWriteMask = .alpha

            let mainNode = SCNNode(geometry: mainPlane)
            mainNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, objectAnchor.referenceObject.center.y, objectAnchor.referenceObject.center.z)
            mainNode.renderingOrder = -1
            mainNode.opacity = 1
            
            // Play Audio
            node.addAudioPlayer(SCNAudioPlayer(source: self.dingAudio))
            
            // Add the plane visualization to the scene
            node.addChildNode(mainNode)
            
            // Perform a quick animation to visualize the plane on which the image was detected.
            // We want to let our users know that the app is responding to the tracked image.
            self.highlightDetection(on: mainNode, width: physicalWidth, height: physicalHeight, completionHandler: {
                
                // Introduce virtual content
                self.displayDetailView(on: mainNode, xOffset: physicalWidth, yOffset: physicalHeight)
                
                // Animate the WebView to the right
                self.displayWebView(on: mainNode, xOffset: physicalWidth, yOffset: physicalHeight)
                
            })
        }
        
    } //generateViews image anchor
 
    
    // MARK: - SceneKit Helpers
    func displayDetailView(on rootNode: SCNNode, xOffset: CGFloat, yOffset: CGFloat) {
        let detailPlane = SCNPlane(width: xOffset * 1.7, height: yOffset * 1.2)
        detailPlane.cornerRadius = 0.05
        
        let detailNode = SCNNode(geometry: detailPlane)
        detailNode.geometry?.firstMaterial?.diffuse.contents = SKScene(fileNamed: "DrillInfo")
        
        // Due to the origin of the iOS coordinate system, SCNMaterial's content appears upside down, so flip the y-axis.
        detailNode.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        detailNode.position.z -= 0.5
        detailNode.opacity = 0
        
        rootNode.addChildNode(detailNode)
        detailNode.runAction(.sequence([
            .wait(duration: 1.0),
            .fadeOpacity(to: 1.0, duration: 1.5),
            .moveBy(x: 0, y: yOffset, z: -0.05, duration: 1.5),
            .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
            ])
        )
    }
    
    func displayWebView(on rootNode: SCNNode, xOffset: CGFloat, yOffset: CGFloat) {
        // Xcode yells at us about the deprecation of UIWebView in iOS 12.0, but there is currently
        // a bug that does now allow us to use a WKWebView as a texture for our webViewNode
        // Note that UIWebViews should only be instantiated on the main thread!
        DispatchQueue.main.async {
            let request = URLRequest(url: URL(string: "https://www.homedepot.com/p/RIDGID-18-Volt-Lithium-Ion-Cordless-Brushless-1-2-in-Compact-Hammer-Drill-with-2-1-5-Ah-Batteries-and-18-Volt-Charger-R861162SB/304583628")!)
            let request2 = URLRequest(url: URL(string: "https://images.homedepot-static.com/catalog/pdfImages/58/588de76f-9860-4cbc-b080-fd4b28d9ba3e.pdf")!)
            
            let webView = UIWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 672))
            webView.loadRequest(request)
            
            let webView2 = UIWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 672))
            webView2.loadRequest(request2)
            
            let webViewPlane = SCNPlane(width: xOffset * 2.25, height: yOffset * 2.75)
            let webViewPlane2 = SCNPlane(width: xOffset * 2.25, height: yOffset * 2.75)
            
            let webViewNode = SCNNode(geometry: webViewPlane)
            webViewNode.geometry?.firstMaterial?.diffuse.contents = webView
            
            let webViewNode2 = SCNNode(geometry: webViewPlane2)
            webViewNode2.geometry?.firstMaterial?.diffuse.contents = webView2
            
            webViewNode.position.z -= 0.5
            webViewNode.position.y -= rootNode.position.y
            webViewNode.opacity = 0
            webViewNode2.position.z -= 0.51
            webViewNode2.position.y -= rootNode.position.y
            webViewNode2.opacity = 0
            
            rootNode.addChildNode(webViewNode)
            webViewNode.runAction(.sequence([
                .wait(duration: 3.0),
                .fadeOpacity(to: 1.0, duration: 1.5),
                .moveBy(x: xOffset * 2.3, y: 0, z: -0.05, duration: 1.5),
                .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
                ])
            )
            rootNode.addChildNode(webViewNode2)
            webViewNode2.runAction(.sequence([
                .wait(duration: 3.0),
                .fadeOpacity(to: 1.0, duration: 1.5),
                .moveBy(x: xOffset * -2.3, y: 0, z: -0.05, duration: 1.5),
                .moveBy(x: 0, y: 0, z: -0.05, duration: 0.2)
                ])
            )
        }
    }
    
    func highlightDetection(on rootNode: SCNNode, width: CGFloat, height: CGFloat, completionHandler block: @escaping (() -> Void)) {
        let planeNode = SCNNode(geometry: SCNPlane(width: width, height: height))
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        planeNode.position.z += 0.05
        planeNode.opacity = 0
        
        rootNode.addChildNode(planeNode)
        planeNode.runAction(self.imageHighlightAction) {
            block()
        }
    }
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 0.85, duration: 0.25),
            .fadeOut(duration: 0.5),
            .removeFromParentNode()
            ])
    }
    
    // Update function to track AR images on screen
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        if let imageAnchor = anchor as? ARImageAnchor{
            let name = imageAnchor.referenceImage.name!
            // Search the corresponding node for the ar image anchor
            for (index, trackedObject) in trackedImages.enumerated(){
                if(trackedObject.name == name){
                    // Check if track is lost on ar image
                    if(imageAnchor.isTracked){
                        // The image is being tracked
                        trackedObject.node?.isHidden = false // Show or add content
  
                    } else {
                        // The image is lost
                        trackedObject.node?.isHidden = true // Hide or delete content
                        trackedObject.node?.removeFromParentNode()
                        print("\(name) image stopped tracking")
                        //Remove anchor once out of view for it to reappear again
                        sceneView.session.remove(anchor: anchor)
                    }
                    break
                }
            }
            
        } //imageAnchor
    } //renderer didUpdate
} //ARSCNViewDelegate
