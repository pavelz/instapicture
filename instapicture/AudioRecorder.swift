//
// Created by Pavel Zaitsev on 11/23/19.
// Copyright (c) 2019 Pavel Zaitsev. All rights reserved.
//

import Foundation
import AVFoundation

class AudioRecorder {
    func AudioRecorder(vc: ChooserController){
        let recordingSession:AVAudioSession! = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned vc] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        //vc.loadRecordingUI()
                    } else {
                        // failed to record!
                        NSLog("Error recording audio")
                    }
                }
            }
        } catch {
            // failed to record!
            NSLog("Error recording audio")
        }
    }

}
