//
//  MetalRaycast.swift
//  MetalRaycastProblem
//
//  Created by Todd Littlejohn on 1/25/24.
//

import Foundation
import Metal

struct BoundingBox {
    var min = MTLPackedFloat3()
    var max = MTLPackedFloat3()
}

class MetalRaycast {
    
    let device: MTLDevice
    let pipelineState: MTLComputePipelineState
    let commandQueue: MTLCommandQueue
    var outputBuffer: MTLBuffer

    var accelerationStructure: MTLAccelerationStructure? = nil
    
    init() {
        
        guard let device = MTLCreateSystemDefaultDevice() else{
            fatalError()
        }
        
        guard let defaultLibrary = device.makeDefaultLibrary() else { fatalError() }
        guard let computeBoidsFunction = defaultLibrary.makeFunction(name: "compute_raycast") else { fatalError() }
        self.pipelineState = try! device.makeComputePipelineState(function: computeBoidsFunction)
        guard let commandQueue = device.makeCommandQueue() else { fatalError() }
        self.commandQueue = commandQueue
        
        self.outputBuffer = device.makeBuffer(length: MemoryLayout<Float32>.size, options: .storageModeShared)!
        
        self.device = device
        
        setUpAccelerationStructure()
        
    }
    
    func setUpAccelerationStructure() {
        
        var b1Min = MTLPackedFloat3()
        b1Min.x = -3.0
        b1Min.y = -1.0
        b1Min.z = -1.0
        
        var b1Max = MTLPackedFloat3()
        b1Max.x = -1.0
        b1Max.y = 1.0
        b1Max.z = 1.0
        
        var b2Min = MTLPackedFloat3()
        b2Min.x = 1.0
        b2Min.y = -1.0
        b2Min.z = -1.0
        
        var b2Max = MTLPackedFloat3()
        b2Max.x = 3.0
        b2Max.y = 1.0
        b2Max.z = 1.0

        let b1 = BoundingBox(
            min: b1Min,
            max: b1Max
        )
        
        let b2 = BoundingBox(
            min: b2Min,
            max: b2Max
        )
        
        let boundingBoxes: [BoundingBox] = [b1, b2]
        
        let geometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()

        
        geometryDescriptor.boundingBoxBuffer = device.makeBuffer(bytes: boundingBoxes,
                                                                 length: MemoryLayout<BoundingBox>.stride * boundingBoxes.count,
                                                                 options: .storageModeShared)
        
        geometryDescriptor.boundingBoxCount = boundingBoxes.count
        
        let accelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
        accelerationStructureDescriptor.geometryDescriptors = [ geometryDescriptor ]
        
        let sizes: MTLAccelerationStructureSizes
        sizes = device.accelerationStructureSizes(descriptor: accelerationStructureDescriptor)
                
        var accelerationStructure: MTLAccelerationStructure
        accelerationStructure = device.makeAccelerationStructure(size: sizes.accelerationStructureSize)!
        
        self.accelerationStructure = accelerationStructure
        
        let scrathBuffer = device.makeBuffer(length: sizes.buildScratchBufferSize, options: .storageModePrivate)!
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeAccelerationStructureCommandEncoder()!
        commandEncoder.build(accelerationStructure: accelerationStructure,
                                                descriptor: accelerationStructureDescriptor,
                                                scratchBuffer: scrathBuffer,
                                                scratchBufferOffset: 0)

        commandEncoder.endEncoding()
        commandBuffer.commit()
        
    }
    
    private func encoderAddCommand( encoder: MTLComputeCommandEncoder ) {
        
        encoder.setComputePipelineState(pipelineState)
        encoder.setBuffer(outputBuffer, offset: 0, index: 0)
        encoder.setAccelerationStructure(accelerationStructure, bufferIndex: 1)

        let gridSize = MTLSize(width: 1, height: 1, depth: 1)
        var threadGroupSize = 1
//        if threadGroupSize > arrayLength {
//            threadGroupSize = arrayLength
//        }
        
        let threadsPerThreadgroup = MTLSize(width: threadGroupSize, height: 1, depth: 1)
        let threadgroupCount = MTLSize(width: (gridSize.width + threadGroupSize - 1) / threadGroupSize, height: 1, depth: 1)
        encoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerThreadgroup)

    }

    
    func sendComputeRaycastCommandAndFetchResult() -> Float32 {
                
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { fatalError() }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { fatalError() }
        self.encoderAddCommand(encoder: computeEncoder)
        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let resultsBufferPtr = outputBuffer.contents()
        return resultsBufferPtr.load(fromByteOffset: 0, as: Float32.self)

    }



}
