//
//  Metal.swift
//  vql
//
//  Created by len on 2015/11/8.
//  Copyright © 2015年 len. All rights reserved.
//

import Foundation
import UIKit

class MyMetal
{
    // Metal
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    
    // Pipeline
    var pipelineState: MTLComputePipelineState! = nil
    
    // Command
    var commandQueue: MTLCommandQueue! = nil
    
    // Render
    let mode = "sat"
    let saturationFactor = 5
    var blurWeightTexture:MTLTexture!
    
    func start(view:UIView)
    {
        // camera start:
        
        device = MTLCreateSystemDefaultDevice()
        
        // Metal Layer
        metalLayer = CAMetalLayer()          // 1
        metalLayer.device = device           // 2
        metalLayer.pixelFormat = .BGRA8Unorm // 3
        metalLayer.framebufferOnly = true    // 4 framebufferOnly to true for performance reasons
        metalLayer.frame = view.layer.frame  // 5
        view.layer.addSublayer(metalLayer)   // 6
        
        
        // Pipeline
        // 1 lib
        let defaultLibrary = device.newDefaultLibrary()
        
        
        // 3 render
        
        let kernel = defaultLibrary!.newFunctionWithName(mode)
        
        do
        {
            try pipelineState = device.newComputePipelineStateWithFunction(kernel!)
        } catch let error as NSError {
            print(error)
        }
        
        // Command
        commandQueue = device.newCommandQueue()
        
        blurWeightTexture = generateBlurWeightTexture()
    }
    
    func render(image: UIImage) -> CGImage
    {
        // 1.
        //        let image = UIImage(named: "grand_canyon.jpg")
        let imageRef = image.CGImage
        
        
        
        let imageWidth       = CGImageGetWidth(imageRef)
        let imageHeight      = CGImageGetHeight(imageRef)
        let bytesPerRow = CGImageGetBytesPerRow(imageRef)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        let bitsPerComponent = 8;
        
        var rawData = [UInt8](count: Int(imageWidth * imageHeight * 4), repeatedValue: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        let context = CGBitmapContextCreate(&rawData, imageWidth, imageHeight, bitsPerComponent, bytesPerRow, rgbColorSpace, bitmapInfo.rawValue)
        
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight)), imageRef)
        // 2.
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(imageWidth), height: Int(imageHeight), mipmapped: true)
        
        let texture = device.newTextureWithDescriptor(textureDescriptor)
        
        let region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: Int(bytesPerRow))
        // 3.
        let outTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(texture.pixelFormat, width: texture.width, height: texture.height, mipmapped: false)
        let outTexture = device.newTextureWithDescriptor(outTextureDescriptor)
        //
        let commandBuffer = commandQueue.commandBuffer()
        let commandEncoder = commandBuffer.computeCommandEncoder()
        
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(texture, atIndex: 0)
        commandEncoder.setTexture(outTexture, atIndex: 1)
        
        if (mode == "sat")
        {
            var saturationFactor = AdjustSaturationUniforms(saturationFactor: (Float)(self.saturationFactor))
            let buffer: MTLBuffer = device.newBufferWithBytes(&saturationFactor, length: sizeof(AdjustSaturationUniforms), options: [])
            commandEncoder.setBuffer(buffer, offset: 0, atIndex: 0)
        }
        else if (mode == "blur")
        {
            commandEncoder.setTexture(blurWeightTexture, atIndex: 2)
        }
        
        let threadGroupCount = MTLSizeMake(8, 8, 1)
        let threadGroups = MTLSizeMake(texture.width / threadGroupCount.width, texture.height / threadGroupCount.height, 1)
        
        commandQueue = device.newCommandQueue()
        commandQueue.insertDebugCaptureBoundary()
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // After GPU done
        if (true)
        {
            let imageSize = CGSize(width: texture.width, height: texture.height)
            
            let bytesPerPixel = Int(bytesPerRow / Int(imageSize.width))
            let bitsPerPixel = 8 * bytesPerPixel
            let imageByteCount = Int(imageSize.width * imageSize.height) * bytesPerPixel
            
            var imageBytes = [UInt8](count: imageByteCount, repeatedValue: 0)
            let region = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
            
            outTexture.getBytes(&imageBytes, bytesPerRow: Int(bytesPerRow), fromRegion: region, mipmapLevel: 0)
            
            //
            
            let providerRef = CGDataProviderCreateWithCFData(
                NSData(bytes: &imageBytes, length: imageBytes.count * sizeof(UInt8))
            )
            
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
            let renderingIntent = CGColorRenderingIntent.RenderingIntentDefault
            
            return CGImageCreate(Int(imageSize.width), Int(imageSize.height), bitsPerComponent, bitsPerPixel, Int(bytesPerRow), rgbColorSpace, bitmapInfo, providerRef, nil, false, renderingIntent)!
        }
    }
    
    func generateBlurWeightTexture() -> MTLTexture
    {
        let radius:Float = 10
        let sigma:Float  = radius / 2.0
        let size:Int   = Int(round(radius * 2)) + 1
        
        var delta:Float    = 0.0
        var expScale:Float = 0.0
        if (radius > 0.0)
        {
            delta = (radius * 2.0) / (Float(size) - 1.0)
            expScale = -1.0 / (2.0 * sigma * sigma);
        }
        
        
        var weights = [Float](count: size * size, repeatedValue: 0.0)
        
        var weightSum:Float = 0.0;
        var y = -radius;
        for (var j = 0; j < size; ++j)
        {
            var x = -radius
            
            for (var i = 0; i < size; ++i)
            {
                let weight = exp(Float(x * x + y * y) * expScale);
                weights[j * size + i] = weight;
                weightSum += weight;
                x += delta
            }
            y += delta
        }
        
        let weightScale:Float = 1.0 / weightSum
        for (var j = 0; j < size; ++j)
        {
            for (var i = 0; i < size; ++i)
            {
                weights[j * size + i] *= weightScale;
            }
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.RGBA8Unorm,
            width: size,
            height: size,
            mipmapped: false)
        let texture = device.newTextureWithDescriptor(textureDescriptor)
        
        let region = MTLRegionMake2D(0, 0, size, size)
        
        let bpr = Int(sizeof(Float) * size)
        texture.replaceRegion(region,
            mipmapLevel: 0,
            slice: 0,
            withBytes: weights,
            bytesPerRow: bpr,
            bytesPerImage: bpr * size)
        return texture
    }
}