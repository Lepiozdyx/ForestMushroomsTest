import Foundation
import FirebaseCore

class AppInitializer {
    let identityCollector = IdentityCollector()
    let postRequestManager = PostRequestManager()
    let realtimeDataClient = RealtimeDatabaseClient()
    
    var identitySnapshot: IdentitySnapshot?
    var desiredURLString: String?
    
    func InitializeApp(attToken: Data, callback: @escaping (String) -> Void) {
        startChecking(callback: callback)
        realtimeDataClient.fetchJSON() { result in
            print(result)
            switch result {
            case .success(let json):
                let urlString = AppSettingsManager.FBRDUrlKey
                let endpointString = AppSettingsManager.FBRDEndpointKey
                if let url = json[urlString] as? String, let endpoint = json[endpointString] as? String {
                    self.desiredURLString = "https://" + url + endpoint
                }
                
            case .failure(let error):
                print("Error fetching JSON: \(error)")
            }
        }
        identityCollector.collectAll(attToken: attToken, completion: { identitySnapshot in
            self.identitySnapshot = identitySnapshot
        })
    }
    
    func startChecking(callback: @escaping (String) -> Void) {
        var checksLeft = 15
        _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if let ids = self.identitySnapshot, let url = self.desiredURLString {
                timer.invalidate()
                self.postRequestManager.sendPost(url: url, identitySnapshot: ids, backendUrlKey: AppSettingsManager.BackendURLKey, backendEndpointKey: AppSettingsManager.BackendEndpointKey) { result in
                    switch result {
                    case .success(let responseString):
                        print("Url fetched: \(responseString)")
                        callback(responseString)
                    case .failure(_):
                        callback("")
                    }
                }
            } else {
                checksLeft -= 1
                if checksLeft <= 0 {
                    timer.invalidate()
                    callback("")
                }
            }
        }
    }
}
