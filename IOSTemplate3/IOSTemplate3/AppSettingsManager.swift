import Foundation

class AppSettingsManager {
    public static var FBRDUrlKey: String {
        openPlist()?["FBRDUrl"] as? String ?? ""
    }
    
    public static var FBRDEndpointKey: String {
        openPlist()?["FBRDEndpoint"] as? String ?? ""
    }
    
    public static var BackendURLKey: String {
        openPlist()?["BackendURL"] as? String ?? ""
    }
    
    public static var BackendEndpointKey: String {
        openPlist()?["BackendEndpoint"] as? String ?? ""
    }
    
    public static var HardcodedUrl: String {
        openPlist()?["HardcodedUrl"] as? String ?? ""
    }
    
    private static var plistCache: [String: Any]?
    
    private static func openPlist() -> [String: Any]? {
        if let cached = plistCache {
            return cached
        }
        
        if let url = Bundle.main.url(forResource: "AppSettings", withExtension: "plist"),
           let data = try? Data(contentsOf: url) {
            do {
                let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                let dict = plist as? [String: Any]
                print("AppSettings.plist loaded: \(dict ?? [:])")
                plistCache = dict
            } catch {
                print("Error reading plist: \(error)")
            }
        }
        return plistCache
    }
}
