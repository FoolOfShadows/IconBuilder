//
//  ViewController.swift
//  IconBuilder
//
//  Created by Fool on 2/6/19.
//  Copyright © 2019 Fool. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    var chosenImage: NSImage?
    var imageName = "Icon"
    
    var sizes = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func importScreenshot(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["jpg", "jpeg", "png"]
        
        panel.begin { [unowned self] result in
            if result == NSApplication.ModalResponse.OK {
                guard let imageURL = panel.url else { return }
                let imageURLWithoutPath = imageURL.deletingPathExtension()
                self.imageName = imageURLWithoutPath.lastPathComponent
                self.chosenImage = NSImage(contentsOf: imageURL)
                self.imageView.image = self.chosenImage
            }
        }
    }
    
    @IBAction func addSize(_ sender: NSButton) {
        if sender.state == .on {
            sizes.append(sender.title)
        } else if sender.state == .off {
            sizes = sizes.filter {$0 != sender.title}
        }
    }
    
    @IBAction func addAllSizes(_ sender: NSButton) {
        if sender.state == .on {
            sizes = ["16", "32", "64", "128", "256", "512", "1024"]
        } else if sender.state == .off {
            sizes = [String]()
        }
    }
    
    @IBAction func export(_ sender: NSButton) {
        //Get array of requested sizes
        let cgSizes = sizes.compactMap { CGFloat(Int($0)!/2) }
        //Make sure sizes have been selected
        //FIXME: will need to report to the user if no sizes have been selected
        if !cgSizes.isEmpty {
            let panel = NSSavePanel()
            //Prefill the file name field with the name of the image
            panel.nameFieldStringValue = self.imageName
            //Only saving png's at this point
            panel.allowedFileTypes = ["png"]
            panel.begin { result in
                if result == NSApplication.ModalResponse.OK {
                    guard let url = panel.url else { return }
                    //Iterate through all the requested sizes and create new images accordingly
                    for theSize in cgSizes {
                        //To automatically rename the files with the size appended
                        let name = url.lastPathComponent.replacingOccurrences(of: ".png", with: "")
                        let newURL = url.deletingLastPathComponent().appendingPathComponent("\(name) \(Int(theSize)*2).png")
                        print("Processing size \(theSize)")
                        guard let image = self.chosenImage?.resizeTo(theSize) else { return }
                        
                        if image.pngWrite(to: newURL, options: .withoutOverwriting) {
                            print("File saved")
                        }
                    }
                }
            }
        }
    }

}

func whatsBigger(h:CGFloat, w:CGFloat) -> CGFloat {
    if h > w || h == w {
        return h
    } else if  w > h {
        return w
    }
    return 0
}

//Takes the size of an object and determines the ratio of the height and width
func sizeRatio(_ size: NSSize) -> NSSize {
    if size.height > size.width {
        return NSSize(width: (size.width/size.height), height: 1.0)
    } else if size.width > size.height {
        return NSSize(width: 1.0, height: (size.height/size.width))
    }
    return NSSize(width: 1.0, height: 1.0)
}

func setImageExportSize(_ requestedSize: String) -> [CGFloat] {
    var sizes = [CGFloat]()
    if requestedSize == "All" {
        sizes = [16, 32, 64, 128, 256, 512]
    } else {
        guard let chosenValue = Int(requestedSize) else { return [] }
        sizes = [CGFloat(chosenValue/2)]
    }
    
    return sizes
}

extension NSImage {
    func resizeTo(_ newSize:CGFloat) -> NSImage {
        //Get the size ratio of the original image and adjust the output accordingly
        let imageRatio = sizeRatio(self.size)

        
        //Adjust the final size of the out put image based on the dimensions of the original image
        let reSized = NSMakeSize(newSize * imageRatio.width, newSize * imageRatio.height)
        //print("Ratio: \(imageRatio), New size: \(reSized)")
        let newImage = NSImage(size: reSized)
        newImage.lockFocus()
        self.draw(in: NSMakeRect(0, 0, reSized.width, reSized.height), from: NSMakeRect(0, 0, self.size.width, self.size.height), operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = reSized
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
