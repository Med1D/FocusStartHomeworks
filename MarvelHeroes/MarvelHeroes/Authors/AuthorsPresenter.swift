//
//  AuthorsPresenter.swift
//  MarvelHeroes
//
//  Created by Иван Медведев on 02/12/2019.
//  Copyright © 2019 Medvedev. All rights reserved.
//

import Foundation

final class AuthorsPresenter
{
	var authorsRouter: IAuthorsRouter
	var repository: IRepository
	weak var authorsView: IAuthorsView?

	init(authorsRouter: IAuthorsRouter, repository: IRepository) {
		self.authorsRouter = authorsRouter
		self.repository = repository
	}

	var authorsDataWrapper: AuthorsDataWrapper?
	var imagesStringURL: [String] = []
	var imagesData: [Data] = []
	let dispatchGroup = DispatchGroup()
	let dispatchQueue = DispatchQueue(label: "loadAuthors", qos: .userInitiated)
}

extension AuthorsPresenter: IAuthorsPresenter
{
	func getAuthors(withAuthorName name: String?) {
		self.dispatchQueue.async {
			print("[---Start Authors Module---]")
			self.loadAuthorsImages(withAuthorName: name)
			self.dispatchGroup.notify(queue: .main) {
				print("| 3.1) Reload")
				print("[----End Authors Module----]")
				self.authorsView?.reloadData(withAuthorsCount: self.getAuthorsCount())
			}
		}
	}
	func getAuthorsCount() -> Int {
		return self.authorsDataWrapper?.data?.results?.count ?? 0
	}
	func getAuthor(at index: Int) -> Author? {
		let author = self.authorsDataWrapper?.data?.results?[index]
		return author
	}
	func getAuthorImageData(at index: Int) -> Data {
		return self.imagesData[index]
	}
	func onCellPressed(author: Author) {
		self.authorsRouter.pushModuleWithAuthorInfo(author: author)
	}
}

extension AuthorsPresenter
{
	private func loadAuthorsImages(withAuthorName name: String?) {
		self.dispatchGroup.enter()
		print("| 1.1) Loading authors.")
		self.repository.getAuthors(withAuthorName: name) { [weak self] authorsResult in
			guard let self = self else { return }
			switch authorsResult {
			case .success(let authorsDataWrapper):
				self.authorsDataWrapper = authorsDataWrapper
				print("| 1.2) Authors were loaded.")
			case .failure(let error):
				assertionFailure(error.localizedDescription)
			}
			self.imagesStringURL.removeAll()
			self.imagesData.removeAll()
			self.dispatchGroup.leave()
		}
		self.dispatchGroup.wait()
		print("| 2.1) Loading images.")
		self.authorsDataWrapper?.data?.results?.forEach { [weak self] author in
			guard let self = self else { return }
			if let path = author.thumbnail?.path, let thumbnailExtension = author.thumbnail?.thumbnailExtension {
				self.imagesStringURL.append( path + ImageSize.medium + thumbnailExtension)
			}
		}
		self.imagesStringURL.forEach { [weak self] imageURLString in
			guard let self = self else { return }
			self.dispatchGroup.enter()
			self.repository.getImage(urlString: imageURLString, { dataResult in
				switch dataResult {
				case .success(let data):
					if let data = data {
						self.imagesData.append(data)
					}
				case .failure(let error):
					assertionFailure(error.localizedDescription)
				}
				self.dispatchGroup.leave()
			})
		}
		self.dispatchGroup.wait()
		print("| 2.2) Images were loaded.")
	}
}
