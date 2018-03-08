import Foundation

/// Defines where the user defaults are stored
public enum TimeStoragePolicy {
    /// Uses `UserDefaults.Standard`
    case standard
    /// Attempts to use the specified App Group ID (which is the String) to access shared storage.
    case appGroup(String)

    public init(appGroupID: String?) {
        if let appGroupID = appGroupID {
            self = .appGroup(appGroupID)
        } else {
            self = .standard
        }
    }
}

public struct TimeStorage {
    private var userDefaults: UserDefaults
    private let kDefaultsKey = "KronosStableTime"

    var stableTime: TimeFreeze? {
        get {
            guard let stored = self.userDefaults.value(forKey: kDefaultsKey) as? [String: TimeInterval],
                let previousStableTime = TimeFreeze(from: stored) else
            {
                return nil
            }

            return previousStableTime
        }

        set {
            guard let newFreeze = newValue else {
                return
            }

            self.userDefaults.set(newFreeze.toDictionary(), forKey: kDefaultsKey)
        }
    }

    public init(storagePolicy: TimeStoragePolicy) {
        switch storagePolicy {
        case .standard:
            self.userDefaults = .standard
        case .appGroup(let groupName):
            self.userDefaults = UserDefaults(suiteName: groupName) ?? .standard
        }
    }
}
