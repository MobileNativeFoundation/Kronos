import Foundation

enum UserDefaultsState: Equatable {
    case standard
    case appGroup(String)

    static func makeState(appGroupID: String?) -> UserDefaultsState {
        if let appGroupID = appGroupID {
            return .appGroup(appGroupID)
        } else {
            return .standard
        }
    }

    static func == (lhs: UserDefaultsState, rhs: UserDefaultsState) -> Bool {
        switch (lhs, rhs) {
        case (.standard, .standard):
            return true
        case (.appGroup(let group1), .appGroup(let group2)):
            return group1 == group2
        default:
            return false
        }
    }
}

struct DefaultsController {
    private static var userDefaults: UserDefaults = .standard
    private static let kDefaultsKey = "KronosStableTime"

    private static var userDefaultsState: UserDefaultsState = .standard {
        didSet {
            guard oldValue != self.userDefaultsState else {
                return
            }

            switch self.userDefaultsState {
            case .standard:
                self.userDefaults = .standard
            case .appGroup(let groupName):
                self.userDefaults = UserDefaults(suiteName: groupName) ?? .standard
            }
        }
    }

    static var stableTime: TimeFreeze? {
        get {
            guard let stored = self.userDefaults.value(forKey: kDefaultsKey) as? [String: TimeInterval],
                let previousStableTime = TimeFreeze(from: stored) else
            {
                return nil
            }

            return previousStableTime
        }

        set {
            self.userDefaults.set(newValue?.toDictionary(), forKey: kDefaultsKey)
        }
    }

    static func updateAppGroupID(_ groupID: String?) {
        self.userDefaultsState = .makeState(appGroupID: groupID)
    }
}
