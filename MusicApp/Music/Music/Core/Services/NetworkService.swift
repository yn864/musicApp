import Foundation

// MARK: - NetworkServiceProtocol
protocol NetworkServiceProtocol {
    // MARK: - Fetch Lists
    func fetchSongs() async throws -> [Song]
    func fetchAlbums() async throws -> [Album]
    func fetchArtists() async throws -> [Artist]

    // MARK: - Fetch Single Entity by ID (NEW)
    func fetchSong(by id: String) async throws -> Song?
    func fetchAlbum(by id: String) async throws -> Album?
    func fetchArtist(by id: String) async throws -> Artist?
    
    func fetchImage(from urlString: String) async throws -> Data?
}

// MARK: - NetworkService Implementation (using URLSession)
final class NetworkService: NetworkServiceProtocol {
    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    // MARK: - Fetch Lists (Implementation)
    func fetchSongs() async throws -> [Song] {
        let endpointURL = baseURL.appendingPathComponent("songs")
        return try await fetchData(from: endpointURL, as: [Song].self)
    }

    func fetchAlbums() async throws -> [Album] {
        let endpointURL = baseURL.appendingPathComponent("albums")
        return try await fetchData(from: endpointURL, as: [Album].self)
    }

    func fetchArtists() async throws -> [Artist] {
        let endpointURL = baseURL.appendingPathComponent("artists")
        return try await fetchData(from: endpointURL, as: [Artist].self)
    }

    // MARK: - Fetch Single Entity by ID (Implementation) (NEW)
    func fetchSong(by id: String) async throws -> Song? {
        let endpointURL = baseURL.appendingPathComponent("songs").appendingPathComponent(id)
        return try await fetchData(from: endpointURL, as: Song.self)
    }

    func fetchAlbum(by id: String) async throws -> Album? {
        let endpointURL = baseURL.appendingPathComponent("albums").appendingPathComponent(id)
        return try await fetchData(from: endpointURL, as: Album.self)
    }

    func fetchArtist(by id: String) async throws -> Artist? {
        let endpointURL = baseURL.appendingPathComponent("artists").appendingPathComponent(id)
        return try await fetchData(from: endpointURL, as: Artist.self)
    }
    
    func fetchImage(from urlString: String) async throws -> Data? {
        let fullURLString = Config.apiBaseURLString + "/" + urlString
        guard let url = URL(string: fullURLString) else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.httpError(statusCode: -1)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            print("HTTP Error: \(httpResponse.statusCode) for URL: \(url)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    // MARK: - Generic Helper for Fetching Data
    private func fetchData<T: Codable>(from url: URL, as type: T.Type) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.httpError(statusCode: -1)
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            print("HTTP Error: \(httpResponse.statusCode) for URL: \(url)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let decodedObject = try JSONDecoder().decode(type, from: data)
            return decodedObject
        } catch let decodingError {
            print("Decoding Error for URL: \(url), Error: \(decodingError)")
            throw NetworkError.decodingError(decodingError)
        }
    }
}

// MARK: - NetworkError Enum
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .httpError(let statusCode):
            return "HTTP Error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Decoding Error: \(error.localizedDescription)"
        }
    }
}
