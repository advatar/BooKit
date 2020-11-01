import UIKit

public struct Config {

    struct Keys {
         static let appointmentsCalendarIdentifier = "appointmentsCalendarIdentifier"

 }

    static let current: Config = Config()

    let defaults: UserDefaults

    public init(
        defaults: UserDefaults = UserDefaults()
    ) {
        self.defaults = defaults
    }

    public var appointmentsCalendarIdentifier: String? {
        get {
            let k = defaults.string(forKey: Keys.appointmentsCalendarIdentifier )
            guard k != nil  else { return nil }
            return k
        }
        set { defaults.set(newValue, forKey: Keys.appointmentsCalendarIdentifier ) }
    }

}



struct BooKit {
    var text = "Hello, World!"
}
