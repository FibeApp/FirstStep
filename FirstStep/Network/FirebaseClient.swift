import Firebase

final class FirebaseClient {
    static let shared = FirebaseClient()

    private init() {}
    
    func createPerson(withEmail email: String, uid: String) throws {
        let person = Person(username: email, email: email)
        try Firestore.firestore().collection("persons").document(uid).setData(from: person)
    }
}
