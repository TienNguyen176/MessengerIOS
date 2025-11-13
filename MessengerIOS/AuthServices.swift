import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase
import GoogleSignIn

class AuthService {
    
    static let shared = AuthService()
    
    private let auth = Auth.auth()
    private let databaseRef = Database.database(
        url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app/"
    ).reference()
    
    private init() {}
    
    // MARK: - Register User
    func register(
        name: String,
        email: String,
        password: String,
        dob: Date,
        genderId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let uid = authResult?.user.uid else {
                completion(.failure(NSError(domain: "RegisterError", code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "UID not found."])))
                return
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let dobString = dateFormatter.string(from: dob)
            
            let userData: [String: Any] = [
                "user_name": name,
                "email": email,
                "avatarUrl": "",
                "bio": "",
                "gender_id": genderId,
                "dob": dobString,
                "chat_ids": [:],
                "friends": [:],
                "blockedUsers": [:],
                "allowMessagesFrom": "type_03",
                "status": [
                    "status_id": "status_01",
                    "last_seen": Int(Date().timeIntervalSince1970 * 1000)
                ],
                "friendRequests": [
                    "sentRequests": [:],
                    "receivedRequests": [:]
                ]
            ]
            
            self.databaseRef.child("users").child(uid).setValue(userData) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Email Login
    func login(
        email: String,
        password: String,
        remember: Bool,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                    print("🔥 FIREBASE LOGIN ERROR:", error)
                    print("🔥 ERROR CODE:", (error as NSError).code)
                    completion(.failure(error))
                    return
                }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "AuthService", code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "User not found."])))
                return
            }
            
            // Cập nhật last_seen
            let lastSeen = Int(Date().timeIntervalSince1970 * 1000)
            let userRef = self.databaseRef.child("users").child(user.uid)
            userRef.child("status").updateChildValues([
                "status_id": "status_01",
                "last_seen": lastSeen
            ])
            
            // Lưu Remember Me
            UserDefaults.standard.set(remember, forKey: "rememberUser")
            if remember {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            completion(.success(()))
        }
    }
    
    // MARK: - Google Login
    func loginWithGoogle(
        presentingVC: UIViewController,
        remember: Bool,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "AuthService", code: 0,
                                        userInfo: [NSLocalizedDescriptionKey: "Missing clientID"])))
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: presentingVC) { user, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
            else {
                completion(.failure(NSError(domain: "GoogleSignIn", code: 0,
                                            userInfo: [NSLocalizedDescriptionKey: "Missing authentication object"])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let user = authResult?.user else {
                    completion(.failure(NSError(domain: "AuthService", code: 0,
                                                userInfo: [NSLocalizedDescriptionKey: "User object is nil"])))
                    return
                }
                
                // Lưu Remember Me
                UserDefaults.standard.set(remember, forKey: "rememberUser")
                if remember, let email = user.email {
                    UserDefaults.standard.set(email, forKey: "userEmail")
                }
                
                completion(.success(user))
            }
        }
    }
}
