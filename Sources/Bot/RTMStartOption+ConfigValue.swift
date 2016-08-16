import WebAPI
import Config

extension RTMStartOption: ConfigValue {
    public static func makeConfigValue(from string: String) throws -> RTMStartOption {
        let pair = string.components(separatedBy: "=")
        
        guard
            pair.count == 2,
            let key = pair.first,
            let value = pair.last,
            let result = RTMStartOption(key: key, value: value)
            else { throw ConfigValueError.unableToConvert(value: string, to: RTMStartOption.self) }
        
        return result
    }
}
