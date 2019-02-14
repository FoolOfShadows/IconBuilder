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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func importScreenshot(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["jpg", "png"]
        
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
    
    @IBAction func export(_ sender: NSButton) {
        guard let chosenValue = Int(sender.title) else { return }
        guard let image = chosenImage?.resizeTo(CGFloat(chosenValue/2)) else { return }
        //print("Have the image of size \(image.size.width) x \(image.size.height)")
        
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["png"]
        panel.nameFieldStringValue = "\(imageName) \(sender.title)"
        
        panel.begin { result in
            if result == NSApplication.ModalResponse.OK {
                guard let url = panel.url else { return }
                if image.pngWrite(to: url, options: .withoutOverwriting) {
                    print("File saved")
                }
            }
        }
    }

}

extension NSImage {
    func resizeTo(_ newSize:CGFloat) -> NSImage {
        //FIXME: I'll get better results if I can figure out the h to w ration
        //of the original image and adjust the output accordingly
        var imageRatio:Float = 0.0
        if self.size.width > self.size.height {
            imageRatio = Float(self.size.width / self.size.height)
        } else {
            imageRatio = Float(self.size.height / self.size.width)
        }
        
        let reSized = NSMakeSize(CGFloat(newSize), CGFloat(newSize))
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
