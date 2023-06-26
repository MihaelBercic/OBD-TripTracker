//
// Created by Mihael Bercic on 13/02/2022.
//

import Foundation

func webRequest(url: String, method: String, body: Data? = nil, closure: @escaping (Data?, URLResponse?, Error?) -> () = { _, _, _ in }) {
    guard let url = URL(string: url) else { fatalError("URL \(url) failed.") }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.httpBody = body
    URLSession.shared.dataTask(with: request, completionHandler: closure).resume()
}

func fetchData<T: Decodable>(url: String, method: String, body: Data? = nil, type: T.Type, _ closure: @escaping (T) -> () = { _ in }) {
    webRequest(url: url, method: method, body: body) { data, response, error in
        guard let data = data else { return }
        guard let decoded = try? JSONDecoder().decode(type, from: data) else { fatalError("It was not possible to decode into \(type).") }
        closure(decoded)
    }

}

