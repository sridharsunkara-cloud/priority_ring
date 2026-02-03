import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Retrieve custom "type" from payload
            if let type = bestAttemptContent.userInfo["type"] as? String, type == "RING" {
                // Set Critical Interruption Level
                if #available(iOS 15.0, *) {
                    bestAttemptContent.interruptionLevel = .critical
                }
                
                // Retrieve user-selected nuclear ringtone from shared UserDefaults
                // Note: Requires App Groups for shared access between App and Extension
                let defaults = UserDefaults(suiteName: "group.com.priorityring")
                let ringtone = defaults?.string(forKey: "ring_nuclear") ?? "calm_emergency.mp3"
                
                bestAttemptContent.sound = UNNotificationSound.criticalSoundNamed(
                    UNNotificationSoundName(rawValue: ringtone),
                    withAudioVolume: 1.0
                )
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
