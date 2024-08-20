import Foundation
import AVFoundation
import Accelerate

class AudioFFTAnalyzer {
    

    
    private var audioFile: AVAudioFile?
    private var audioFormat: AVAudioFormat?
    private var audioFrameCount: AVAudioFrameCount = 0
    private let fftSize: Int = 4096 * 3
    private let sampleRate : Double // Assuming standard sample rate
    
    init?(audioURL: URL) {
        do {
            audioFile = try AVAudioFile(forReading: audioURL)
            audioFormat = audioFile?.processingFormat
            audioFrameCount = AVAudioFrameCount(audioFile?.length ?? 0)
            sampleRate = audioFormat?.sampleRate ?? 44100
        } catch {
            print("Error loading audio file: \(error)")
            return nil
        }
    }
    
    
    
    func getFFTBars(atTime milliseconds: Int, barCount: Int) -> AudioFFT? {
        guard let audioFile = audioFile, let audioFormat = audioFormat else {
            print("Audio file not properly initialized")
            return nil
        }
        
        let framePosition = AVAudioFramePosition(Double(milliseconds) / 1000.0 * sampleRate)
        guard framePosition < audioFrameCount else {
            print("Requested time is beyond audio duration")
            return nil
        }
        
        audioFile.framePosition = framePosition
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(fftSize))!
        do {
            try audioFile.read(into: buffer)
        } catch {
            print("Error reading audio file: \(error)")
            return nil
        }
        
        guard let floatData = buffer.floatChannelData?[0] else {
            print("Could not get float channel data")
            return nil
        }
        
        let fftMagnitudes = performFFT(on: Array(UnsafeBufferPointer(start: floatData, count: fftSize)))
        let usefulRange = min(fftSize / 2, 1024 / 4)
        let bars = resampleFFTMagnitudes(Array(fftMagnitudes[0..<usefulRange]), toSize: barCount)
        return AudioFFT(startTime: milliseconds, bars: bars)
    }

    
    private func performFFT(on samples: [Float]) -> [Float] {
        let log2n = vDSP_Length(log2(Float(fftSize)))
        let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))!
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        let realPart = UnsafeMutablePointer<Float>.allocate(capacity: fftSize)
        let imaginaryPart = UnsafeMutablePointer<Float>.allocate(capacity: fftSize)
        defer {
            realPart.deallocate()
            imaginaryPart.deallocate()
        }
        
        var windowedSamples = [Float](repeating: 0, count: fftSize)
        for i in 0..<fftSize {
           let n = Float(i)
           let N = Float(fftSize)
           windowedSamples[i] = samples[i] * (0.5 - 0.5 * cos(2 * Float.pi * n / (N - 1)))
       }
        
        // Copy samples to realPart and initialize imaginaryPart to zeros
        realPart.initialize(from: windowedSamples, count: min(windowedSamples.count, fftSize))
        if samples.count < fftSize {
            (realPart + samples.count).initialize(repeating: 0, count: fftSize - samples.count)
        }
        imaginaryPart.initialize(repeating: 0, count: fftSize)
        
        var splitComplex = DSPSplitComplex(realp: realPart, imagp: imaginaryPart)
        
        vDSP_fft_zip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
        
        
        var normalizedMagnitudes = [Float](repeating: 0, count: fftSize / 2)
        vDSP_vsmul(magnitudes, 1, [2.0 / Float(fftSize)], &normalizedMagnitudes, 1, vDSP_Length(fftSize / 2))
        
        return normalizedMagnitudes
    }

    
    private func resampleFFTMagnitudes(_ magnitudes: [Float], toSize: Int) -> [Float] {
        let inputLength = magnitudes.count
        var output = [Float](repeating: 0, count: toSize)
        
        let scaleFactor = Float(inputLength - 1) / Float(toSize - 1)
        
        for i in 0..<toSize {
            let position = Float(i) * scaleFactor
            let index = Int(position)
            output[i] = magnitudes[index]
        }
        
        // Apply power-law scaling to emphasize higher magnitudes
        let exponent: Float = 3 // Adjust this value to control the emphasis
        let minValue: Float = 1e-6 // To avoid log(0)
        for i in 0..<toSize {
            output[i] = pow(max(output[i], minValue), exponent)
        }
        
        // Convert to logarithmic frequency scale
        for i in 0..<toSize {
            let frequency = Float(i) * Float(sampleRate) / Float(fftSize)
            let scalingFactor: Float
            if frequency < 500 { // Adjust the frequency threshold as needed
                scalingFactor = log10(max(output[i], minValue) * 100 + 1) // More aggressive scaling for low frequencies
            } else {
                scalingFactor = log10(max(output[i], minValue) * 10 + 1) // Regular scaling for higher frequencies
            }
            output[i] = scalingFactor
        }
        
        // Normalize
        if let maxVal = output.max(), maxVal > 0 {
            for i in 0..<toSize {
                output[i] /= maxVal
            }
        }
        
        return output
    }
    

}


