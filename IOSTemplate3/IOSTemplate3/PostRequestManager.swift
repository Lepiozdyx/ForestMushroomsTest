import Foundation

final class PostRequestManager {
    enum PostRequestError: Error {
        case invalidResponse
        case invalidJSON
    }

    func makeParams(from snapshot: IdentitySnapshot) -> [String: Any] {
        let params: [String: Any?] = [
            "att_token": snapshot.attToken,
            "appsflyer_id": snapshot.appsFlyerId,
            "app_instance_id": snapshot.appInstanceId,
            "uuid": snapshot.uuid.lowercased(),
            "osVersion": snapshot.osVersion,
            "devModel": snapshot.deviceModel,
            "bundle": snapshot.bundleId,
            "fcm_token": snapshot.fcmToken
        ]

        return params.compactMapValues { $0 }
    }

    func base64Encode(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        let result = data.base64EncodedString()
        return result
    }

    func stringifyParams(_ params: [String: Any]) -> String? {
        var queryString = ""
        for param in params {
            if !queryString.isEmpty {
                queryString += "&"
            }
            if let value = param.value as? String {
                queryString += "\(param.key)=\(value)"
            } else {
                queryString += "\(param.key)=\(param.value)"
            }
        }
        print("Data to send: \n\(queryString)")
        return queryString
    }

    func makePostRequest(url: String, data: [String : Any]) -> URLRequest {
        guard let dataString = stringifyParams(data) else {
            fatalError("Failed to stringify params")
        }
        let encodedDataString = base64Encode(dataString) ?? ""
        let fullUrl = url + "?data=" + encodedDataString
        print(fullUrl)
        guard let url = URL(string: fullUrl) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }

    func sendPost(
        url: String,
        identitySnapshot: IdentitySnapshot,
        backendUrlKey: String,
        backendEndpointKey: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let data = makeParams(from: identitySnapshot)
        let request = makePostRequest(url: url, data: data)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(PostRequestError.invalidResponse))
                return
            }
            print("Response data:")
            print(String(data: data, encoding: .utf8) ?? "nil")
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                guard let dictionary = jsonObject as? [String: Any] else {
                    completion(.failure(PostRequestError.invalidJSON))
                    return
                }
                
                if let url = dictionary[backendUrlKey] as? String, let endpoint = dictionary[backendEndpointKey] as? String {
                    let combinedURL = "https://" + url + endpoint
                    completion(.success(combinedURL))
                    return
                }
                
                completion(.failure(PostRequestError.invalidJSON))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
