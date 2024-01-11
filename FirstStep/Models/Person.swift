import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Person: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var avatarLink = ""
}
