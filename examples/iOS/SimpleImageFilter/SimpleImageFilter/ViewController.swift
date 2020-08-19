import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:SaturationAdjustment!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Filtering image for saving
        let testImage = UIImage(named:"WID-small.jpg")!
        let toonFilter = ToonFilter()
        
        do {
            let filteredImage = try testImage.filterWithOperation(toonFilter)
            
            let pngImage = try UIImagePNGRepresentation(filteredImage!)!
            
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
            let fileURL = URL(string:"test.png", relativeTo:documentsDir)!
            try pngImage.write(to:fileURL, options:.atomic)
            
            picture = try PictureInput(image:UIImage(named:"WID-small.jpg")!)
            filter = SaturationAdjustment()
            picture --> filter --> renderView
            picture.processImage(synchronously: true)
//            try _ = testImage.filterWithOperation(filter)
        } catch {
            print("Couldn't write to file with error: \(error)")
        }
    }
}

