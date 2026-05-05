import Foundation
import FirebaseCore
import FirebaseDatabase

enum RealtimeDatabaseError: Error {
    case sdkUnavailable
    case invalidPayload
}

final class RealtimeDatabaseClient {

    func fetchJSON(at path: String? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        let reference: DatabaseReference
        if let path = path, !path.isEmpty {
            reference = Database.database().reference(withPath: path)
        } else {
            reference = Database.database().reference()
        }

        reference.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                completion(.failure(RealtimeDatabaseError.invalidPayload))
                return
            }
            completion(.success(value))
        } withCancel: { error in
            completion(.failure(error))
        }
    }
}
