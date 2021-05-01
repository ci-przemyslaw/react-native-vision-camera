//
//  CameraView+RecordVideo.swift
//  Cuvent
//
//  Created by Marc Rousavy on 16.12.20.
//  Copyright © 2020 Facebook. All rights reserved.
//

import AVFoundation

private var hasLoggedFrameDropWarning = false

extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
  func startRecording(options: NSDictionary, callback: @escaping RCTResponseSenderBlock) {
    cameraQueue.async {
      let errorPointer = ErrorPointer(nilLiteral: ())
      guard let tempFilePath = RCTTempFilePath("mov", errorPointer) else {
        return callback([NSNull(), makeReactError(.capture(.createTempFileError), cause: errorPointer?.pointee)])
      }
      let tempURL = URL(string: "file://\(tempFilePath)")!
      if let flashMode = options["flash"] as? String {
        // use the torch as the video's flash
        self.setTorchMode(flashMode)
      }

      // TODO: Start recording with AVCaptureVideoDataOutputSampleBufferDelegate
      // TODO: The startRecording() func cannot be async because RN doesn't allow both a callback and a Promise in a single function. Wait for TurboModules?
      // return ["path": tempFilePath]
    }
  }

  func stopRecording(promise: Promise) {
    cameraQueue.async {
      withPromise(promise) {
        // TODO: Stop recording with AVCaptureVideoDataOutputSampleBufferDelegate
        return nil
      }
    }
  }

  public func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
    // TODO: Add to encoder if recording
    
    if let frameProcessor = frameProcessorCallback {
      // check if last frame was x nanoseconds ago, effectively throttling FPS
      let diff = DispatchTime.now().uptimeNanoseconds - self.lastFrameProcessorCall.uptimeNanoseconds
      let secondsPerFrame = 1.0 / self.frameProcessorFps.doubleValue
      let nanosecondsPerFrame = secondsPerFrame * 1_000_000_000.0
      if diff > UInt64(nanosecondsPerFrame) {
        frameProcessor(sampleBuffer)
        self.lastFrameProcessorCall = DispatchTime.now()
      }
    }
  }

  public func captureOutput(_: AVCaptureOutput, didDrop _: CMSampleBuffer, from _: AVCaptureConnection) {
    if !hasLoggedFrameDropWarning {
      // TODO: Show in React console?
      ReactLogger.log(level: .warning, message: "Dropped a Frame. This might indicate that your Frame Processor is doing too much work. " +
        "Either throttle the frame processor's frame rate, or optimize your frame processor's execution speed.")
      hasLoggedFrameDropWarning = true
    }
  }
}
