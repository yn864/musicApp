import Foundation

enum Config {
    static let apiBaseURLString = "http://192.168.0.106:8000"
    static let apiBaseURL: URL = {
        guard let url = URL(string: apiBaseURLString) else {
            fatalError("Неверный формат baseURL: \(apiBaseURLString)")
        }
        return url
    }()
}
