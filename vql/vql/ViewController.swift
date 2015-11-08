import UIKit
import MobileCoreServices


struct AdjustSaturationUniforms
{
    var saturationFactor: Float
}

class ViewController: UIViewController,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate
{
    // Take photo
    var beenHereBefore = false
    var controller: UIImagePickerController?

    // UI
    var imageView: UIImageView!
    
    
    let myCamera = MyCamera()
    let myMetal = MyMetal()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        myMetal.start(view)
    }
    
    func render(image: UIImage) {
        let imageRef = myMetal.render(image)
        //
        imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .ScaleAspectFit
        
        imageView.image = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)
        imageView.center = view.center
        view.addSubview(imageView)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if beenHereBefore{
            /* Only display the picker once as the viewDidAppear: method gets
            called whenever the view of our view controller gets displayed */
            return;
        } else {
            beenHereBefore = true
        }
        
        if myCamera.isCameraAvailable() && myCamera.doesCameraSupportTakingPhotos(){
            
            controller = UIImagePickerController()
            
            if let theController = controller{
                theController.sourceType = .Camera
                
                theController.mediaTypes = [kUTTypeImage as String]
                
                theController.allowsEditing = false
                theController.delegate = self
                
                presentViewController(theController, animated: true, completion: nil)
            }
            
        } else {
            print("Camera is not available ...")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]){
            
            print("Picker returned successfully")
            
            let mediaType:AnyObject? = info[UIImagePickerControllerMediaType]
            
            if let type:AnyObject = mediaType{
                
                if type is String{
                    let stringType = type as! String
                    
                    if stringType == kUTTypeMovie as String{
                        let urlOfVideo = info[UIImagePickerControllerMediaURL] as? NSURL
                        if let url = urlOfVideo{
                            print("Video URL = \(url)")
                        }
                    }
                        
                    else if stringType == kUTTypeImage as String{
                        /* Let's get the metadata. This is only for images. Not videos */
                        let metadata = info[UIImagePickerControllerMediaMetadata]
                            as? NSDictionary
                        if let theMetaData = metadata{
                            let image = info[UIImagePickerControllerOriginalImage]
                                as? UIImage
                            if let theImage = image{
                                print("Image Metadata = \(theMetaData)")
                                print("Image = \(theImage)")
                                
                                // You've get the image
                                
                                self.render(theImage)
                                print("Rendered via Metal")
                            }
                            
                        }
                    }
                    
                }
            }
            picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        print("Picker was cancelled")
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}

