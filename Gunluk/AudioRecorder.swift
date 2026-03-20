import Foundation
import AVFoundation
import Combine



class AudioRecorder: NSObject, ObservableObject {
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    @Published var kayitYapiliyor = false
    @Published var kayitVar = false
    
    func kayitBaslat() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else { return }
            
            DispatchQueue.main.async {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playAndRecord, mode: .default)
                try? session.setActive(true)
                
                let dosyaYolu = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("kayit.m4a")
                
                let ayarlar: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                self.audioRecorder = try? AVAudioRecorder(url: dosyaYolu, settings: ayarlar)
                self.audioRecorder?.record()
                self.kayitYapiliyor = true
            }
        }
    }
    func kayitDurdur() {
        audioRecorder?.stop()
        kayitYapiliyor = false
        kayitVar = true
    }
    
    func kayitOynat() {
        let dosyaYolu = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kayit.m4a")
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        audioPlayer = try? AVAudioPlayer(contentsOf: dosyaYolu)
        audioPlayer?.play()
    }
}
