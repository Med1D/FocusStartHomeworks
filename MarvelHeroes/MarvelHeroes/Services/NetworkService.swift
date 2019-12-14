//
//  NetworkService.swift
//  MarvelHeroes
//
//  Created by Иван Медведев on 02/12/2019.
//  Copyright © 2019 Medvedev. All rights reserved.
//

import Foundation

typealias DataResult = Result<Data, Error>
typealias DataOptionalResult = Result<Data?, Error>
typealias HeroesResult = Result<HeroesDataWrapper, Error>
typealias ComicsResult = Result<ComicsDataWrapper, Error>
typealias AuthorsResult = Result<AuthorsDataWrapper, Error>

final class NetworkService
{
	private var decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return decoder
	}()
	private let urlBuilder = URLBuilder()
}

extension NetworkService: INetworkService
{
	func getHeroes(heroeName: String?, _ completion: @escaping (HeroesResult) -> Void) {
		guard let url = self.urlBuilder.createURL(withHeroeName: heroeName) else {
			assertionFailure("Wrong url")
			return
		}
		self.fetchData(fromURL: url) { [weak self] dataResult in
			guard let self = self else { return }
			switch dataResult {
			case .success(let data):
				do {
					let heroesDataWrapper = try self.decoder.decode(HeroesDataWrapper.self, from: data)
					completion(.success(heroesDataWrapper))
				}
				catch {
					completion(.failure(NetworkServiceError.dataError(error)))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func getImage(urlString: String, _ completion: @escaping (DataOptionalResult) -> Void ) {
		guard let url = URL(string: urlString) else {
			assertionFailure("Wrong URL")
			return
		}
		self.fetchData(fromURL: url) { dataResult in
			switch dataResult {
			case .success(let data):
				completion(.success(data))
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func getComic(withUrlString urlString: String?, _ completion: @escaping (ComicsResult) -> Void) {
		guard let urlString = urlString, let url = self.urlBuilder.createURL(withUrlString: urlString) else {
			assertionFailure("Wrong URL")
			return
		}
		self.fetchData(fromURL: url) { [weak self] dataResult in
			guard let self = self else { return }
			switch dataResult {
			case .success(let data):
				do {
					let comicsDataWrapper = try self.decoder.decode(ComicsDataWrapper.self, from: data)
					completion(.success(comicsDataWrapper))
				}
				catch {
					completion(.failure(NetworkServiceError.dataError(error)))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func getComics(withComicName name: String?, _ completion: @escaping (ComicsResult) -> Void) {
		guard let url = self.urlBuilder.createURL(withComicName: name) else {
			assertionFailure("Wrong url")
			return
		}
		self.fetchData(fromURL: url) { [weak self] dataResult in
			guard let self = self else { return }
			switch dataResult {
			case .success(let data):
				do {
					let comicsDataWrapper = try self.decoder.decode(ComicsDataWrapper.self, from: data)
					completion(.success(comicsDataWrapper))
				}
				catch {
					completion(.failure(NetworkServiceError.dataError(error)))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func getAuthor(withUrlString urlString: String?, _ completion: @escaping (AuthorsResult) -> Void) {
		guard let urlString = urlString, let url = self.urlBuilder.createURL(withUrlString: urlString) else {
			assertionFailure("Wrong URL")
			return
		}
		self.fetchData(fromURL: url) { [weak self] dataResult in
			guard let self = self else { return }
			switch dataResult {
			case .success(let data):
				do {
					let authorsDataWrapper = try self.decoder.decode(AuthorsDataWrapper.self, from: data)
					completion(.success(authorsDataWrapper))
				}
				catch {
					print(url)
					print(error.localizedDescription)
					completion(.failure(NetworkServiceError.dataError(error)))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}

	func getAuthors(withAuthorName name: String?, _ completion: @escaping (AuthorsResult) -> Void) {
		guard let url = self.urlBuilder.createURL(withAuthorName: name) else {
			assertionFailure("Wrong url")
			return
		}
		self.fetchData(fromURL: url) { [weak self] dataResult in
			guard let self = self else { return }
			switch dataResult {
			case .success(let data):
				do {
					let authorsDataWrapper = try self.decoder.decode(AuthorsDataWrapper.self, from: data)
					completion(.success(authorsDataWrapper))
				}
				catch {
					completion(.failure(NetworkServiceError.dataError(error)))
				}
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
}

extension NetworkService
{
	private func fetchData(fromURL url: URL, _ completion: @escaping (DataResult) -> Void) {

		let session = URLSession.shared

		let dataTask = session.dataTask(with: url) { data, response, error in
			if let sessionError = error {
				completion(.failure(NetworkServiceError.sessionError(sessionError)))
			}

			if let data = data, let response = response as? HTTPURLResponse {
				switch response.statusCode {
				case 400 ..< 500:
					completion(.failure(NetworkServiceError.clientError(response.statusCode)))
				case 500 ..< 600:
					completion(.failure(NetworkServiceError.serverError(response.statusCode)))
				default:
					break
				}
				completion(.success(data))
			}
		}
		dataTask.resume()
	}
}