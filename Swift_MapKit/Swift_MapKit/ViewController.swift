//
//  ViewController.swift
//  Swift_MapKit
//
//  Created by jung on 2023/08/30.
//

import UIKit
import MapKit
import SnapKit
import KakaoMapsSDK

class ViewController: UIViewController {
	// MARK: - Properties
	var viewModel: ViewModelType
	/// 옵저버 추가되었는지 여부
	var _observerAdded: Bool
	///  인증 성공 여부
	var _auth: Bool
	
	var mapController: KMController?
	var mapContainer: KMViewContainer {
		guard let mapContainer = self.view as? KMViewContainer else {
			fatalError()
		}
		return mapContainer
	}
	
	
	// MARK: - Initializers
	required init?(coder aDecoder: NSCoder) {
		viewModel = ViewModel()
		_observerAdded = false
		_auth = false
		
		super.init(coder: aDecoder)
		
		viewModel.presenter = self
	}
	
	deinit {
		mapController?.stopRendering()
		mapController?.stopEngine()
		
		print("deinit")
	}
	
	// MARK: - Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		//KMController 생성.
		mapController = KMController(viewContainer: mapContainer)
		mapController?.delegate = self
		
		//엔진 초기화 및 인증 시도
		mapController?.initEngine()
		mapController?.authenticate()
		// 인증 성공시 MapControllerDelegate의 authenticationSucceeded 호출
	}
	
	override func viewWillAppear(_ animated: Bool) {
		//		addObservers()
		
		viewModel.viewWillAppear()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		//렌더링 중지.
		mapController?.stopRendering()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		//엔진 정지. 추가되었던 ViewBase들이 삭제된다.
		removeObservers()
		mapController?.stopEngine()
	}
}

// MARK: - MapControllerDelegate
extension ViewController: MapControllerDelegate {
	/// 인증 성공시 호출.
	func authenticationSucceeded() {
		// 엔진 시작 및 렌더링 준비.
		// 준비가 끝나면 MapControllerDelegate의 addViews 가 호출된다.
		_auth = true
		mapController?.startEngine()
		mapController?.startRendering() // 렌더링 시작.
	}
	
	/// 인증 실패시 호출.
	func authenticationFailed(_ errorCode: Int, desc: String) {
		print("error code: \(errorCode)")
		print("\(desc)")
		
		// 인증 실패 delegate 호출 이후 5초뒤에 재인증 시도
		DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
			print("retry auth...")
			self.mapController?.authenticate()
		}
	}
	
	/// 그릴 `View(KakaoMap, Roadview)`들을 추가한다.
	/// `StartEngine()` 호출시 호출됨
	func addViews() {
		// 지도(KakaoMap)를 그리기 위한 viewInfo를 생성
		let defaultPosition: MapPoint = MapPoint(longitude: 127.108678, latitude: 37.402001)
		let mapviewInfo: MapviewInfo = MapviewInfo(
			viewName: "mapview",
			viewInfoName: "map",
			defaultPosition: defaultPosition,
			defaultLevel: 14
		)
		
		// KakaoMap을 ViewBase에 추가
		if mapController?.addView(mapviewInfo) == Result.OK {
			//지도(KakaoMap)를 그리기 위한 viewInfo를 생성
			print("OK")
		}
		
		let mapView = mapController?.getView("mapview") as? KakaoMap
		
		mapView?.setLogoPosition(origin: GuiAlignment.init(vAlign: .bottom, hAlign: .left), position: CGPoint(x: 20, y: 20))
		
		_ = mapView?.addCameraStoppedEventHandler(target: self) { owner in
			return owner.cameraMove(_:)
		}
	}
	
	/// Container 뷰가 리사이즈 되었을때 호출된다.
	/// 변경된 크기에 맞게 ViewBase들의 크기를 조절할 필요가 있는 경우 여기에서 수행한다.
	func containerDidResized(_ size: CGSize) {
		//지도뷰의 크기를 리사이즈된 크기로 지정한다.
		let mapView: KakaoMap? = mapController?.getView("mapview") as? KakaoMap
		mapView?.viewRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size)
	}
	
	func viewWillDestroyed(_ view: ViewBase) {
		removeObservers()
	}
}

// MARK: - Observer
extension ViewController {
	func addObservers(){
		NotificationCenter.default.addObserver(
			self, 
			selector: #selector(willResignActive),
			name: UIApplication.willResignActiveNotification,
			object: nil
		)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didBecomeActive),
			name: UIApplication.didBecomeActiveNotification,
			object: nil
		)
		
		_observerAdded = true
	}
	
	func removeObservers(){
		NotificationCenter.default.removeObserver(
			self,
			name: UIApplication.willResignActiveNotification,
			object: nil
		)
		NotificationCenter.default.removeObserver(
			self,
			name: UIApplication.didBecomeActiveNotification,
			object: nil
		)
		
		_observerAdded = false
	}
	
	/// 뷰가 inactive 상태로 전환되는 경우 렌더링 중인 경우 렌더링을 중단.
	@objc func willResignActive() {
		mapController?.stopRendering()
	}
	
	/// 뷰가 active 상태가 되면 렌더링 시작. 엔진은 미리 시작된 상태여야 함.
	@objc func didBecomeActive() {
		mapController?.startRendering()
	}
}

extension ViewController {
	func cameraMove(_ event: CameraActionEventParam) {
		guard let mapView = mapController?.getView("mapview") as? KakaoMap else { return }
		
		let topLeft = mapView.getPosition(CGPoint(x: 0, y: 0))
		let bottomRight = mapView.getPosition(CGPoint(x: view.frame.width, y: view.frame.height))
		let zoomLevel = mapView.zoomLevel
		
		viewModel.userDidChangeCamera(
			topLeft: Location(longitude: topLeft.wgsCoord.longitude, latitude: topLeft.wgsCoord.latitude),
			bottomRight: Location(longitude: bottomRight.wgsCoord.longitude, latitude: bottomRight.wgsCoord.latitude),
			zoomLevel: mapView.zoomLevel
		)
	}
}

extension ViewController: Presentable {
	func userLocationDidUpdate(_ location: Location) {
		if _auth {
			if mapController?.engineStarted == false {
				mapController?.startEngine()
			}
			
			if mapController?.rendering == false {
				mapController?.startRendering()
			}
		}
	}
	
	func usersLocationDidChange(_ locations: [Location]) {
		guard let mapView = mapController?.getView("mapview") as? KakaoMap else { return }
		createLabelLayer(mapView)
		createPoiStyle(mapView)
		createPois(mapView, location: locations)
	}
}

// MARK: Pois
extension ViewController {
	/// LabelLayer 내부에 Poi를 생성하는 거임.
	func createLabelLayer(_ mapView: KakaoMap) {
		let mannager = mapView.getLabelManager()
		let layerOption = LabelLayerOptions(
			layerID: "PoiLayer",
			competitionType: .none,
			competitionUnit: .symbolFirst,
			orderType: .rank,
			zOrder: 0
		)
		let _ = mannager.addLabelLayer(option: layerOption)
	}
	
	func createPoiStyle(_ mapView: KakaoMap) {
		let manager = mapView.getLabelManager()
		
		// PoiBadge는 스타일에도 추가될 수 있다. 이렇게 추가된 Badge는 해당 스타일이 적용될 때 함께 그려진다.
		let icon = PoiIconStyle(symbol: UIImage(systemName: "trash"))
		print("icon: \(icon.description)")
		
		// 5~11, 12~21 에 표출될 스타일을 지정한다.
		let poiStyle = PoiStyle(styleID: "PerLevelStyle", styles: [
			PerLevelPoiStyle(iconStyle: icon, level: 5),
			PerLevelPoiStyle(iconStyle: icon, level: 12)
		])
		manager.addPoiStyle(poiStyle)
	}
	
	func createPois(_ mapView: KakaoMap, location: [Location]) {
		let manager = mapView.getLabelManager()
		let layer = manager.getLabelLayer(layerID: "PoiLayer")
		let poiOption = PoiOptions(styleID: "PerLevelStyle")
		poiOption.rank = 0
		
		poiOption.transformType = .decal
		
		layer?.clearAllItems()
		location.forEach { location in
			let poi = layer?.addPoi(
				option: poiOption,
				at: MapPoint(longitude: location.longitude, latitude: location.latitude)
			)
			poi?.show()
		}
	}
}
