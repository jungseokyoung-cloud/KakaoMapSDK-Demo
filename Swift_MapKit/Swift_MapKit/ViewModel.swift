//
//  퍋즈ㅐㅇ디.swift
//  Swift_MapKit
//
//  Created by jung on 2023/08/31.
//

import Foundation

protocol Presentable {
	func userLocationDidUpdate(_ location: Location)
	func usersLocationDidChange(_ locations: [Location])
}

enum Mode {
	case stub1
	case stub2
	
	@discardableResult
	func toggleMode() -> Mode {
		switch self {
		case .stub1:
			return .stub2
		case .stub2:
			return .stub1
		}
	}
	
	func getData() -> [Location] {
		switch self {
		case .stub1:
			return ViewModel.stubData1
		case .stub2:
			return ViewModel.stubData2
		}
	}
}

protocol ViewModelType {
	var presenter: Presentable? { get set }
	
	func viewWillAppear()
	func userDidChangeCamera(topLeft: Location, bottomRight: Location, zoomLevel: Int)
}

final class ViewModel: ViewModelType {
	var presenter: Presentable?
	var nowDataMode: Mode = .stub1

	func viewWillAppear() {
		presenter?.userLocationDidUpdate(ViewModel.stubViewW)
		presenter?.usersLocationDidChange(nowDataMode.getData())
		nowDataMode.toggleMode()
	}
	
	func userDidChangeCamera(
		topLeft: Location,
		bottomRight: Location,
		zoomLevel: Int
	) {
		print("topLeft: \(topLeft)")
		print("bottomRight: \(bottomRight)")
		print("zoomLevel: \(zoomLevel)")
		
		presenter?.usersLocationDidChange(nowDataMode.getData())
		nowDataMode = nowDataMode.toggleMode()
	}
}

extension ViewModel {
	static let stubViewW = Location(longitude: 127.108678, latitude: 37.40198)
	/*
	topLeft: Location(
		longitude: 127.09717753409159,
		latitude: 37.42611389593196
	 )
		
	bottomRight: Location(
		longitude: 127.1224761303258,
		latitude: 37.382546102525566
	 )
	 */
	static let stubData1 = [
		Location(longitude: 127.0973, latitude: 37.39),
		Location(longitude: 127.108678, latitude: 37.40198),
		Location(longitude: 127.110678, latitude: 37.41198),
	]
	
	static let stubData2 = [
		Location(longitude: 127.0973, latitude: 37.39),
		Location(longitude: 127.108678, latitude: 37.40198),
		Location(longitude: 127.100678, latitude: 37.6000),
		Location(longitude: 127.122378, latitude: 37.42198)
	]
	
//	func create5Location(_ topLeft: Location, _ bottomRight: Location) -> [Location] {
//		let leftLong = topLeft.longitude < bottomRight.longitude ? topLeft.longitude : bottomRight.longitude
//		let rightLong = topLeft.longitude > bottomRight.longitude ? topLeft.longitude : bottomRight.longitude
//		let toplat = topLeft.latitude < bottomRight.longitude ? topLeft.longitude : bottomRight.longitude
//		let bottomlat = topLeft.longitude < bottomRight.longitude ? topLeft.longitude : bottomRight.longitude
//	}
}
