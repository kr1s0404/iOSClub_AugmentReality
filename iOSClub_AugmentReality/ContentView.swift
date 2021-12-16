//
//  ContentView.swift
//  iOSClub_AugmentReality
//
//  Created by Kris on 12/16/21.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View
{
    var body: some View
    {
        ARViewContainer().ignoresSafeArea()//讓他滿版 可以直接 call uiview
    }
}

struct ARViewContainer: UIViewRepresentable//轉換
{
    
    var imageTrackingView = ARView(frame: .zero)
    
    func makeUIView(context: Context) -> ARView //取 ARView
    {
        // bundle: Bundle.main, bundle: nil 的區別？
        //取得整個 AR 圖片資料夾
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // coordinator to delegate the AR View
        imageTrackingView.session.delegate = context.coordinator //透過 context 取得相機資料 、 coordinator在下方被創建
        
        //https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration?language=objc
        let configuration = ARImageTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 10 // 這裡要變動，上限是100得樣子
        
        // 如果該裝置支援人物遮蔽 手能夠穿過 影片圖片
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) //判斷使用者手機有沒有支援
        {
            // 就在config裡面加上這項功能
            configuration.frameSemantics.insert(.personSegmentationWithDepth)//支持的話 "加入功能"
        }
        else
        {
            print("People Segmentation not enabled.")
        }

        imageTrackingView.session.run(configuration)
        return imageTrackingView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator
    {
        Coordinator(parent: self)//給ARViewContainer
    }
    
    class Coordinator: NSObject, ARSessionDelegate
    {
        // arView
        var parent: ARViewContainer
        
        
        // 影片變數
        var videoPlayer: AVPlayerLooper!
        let queuePlayer = AVQueuePlayer()
        
        init(parent: ARViewContainer)
        {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor])
        {
            
            if let imageAnchor = anchors.first as? ARImageAnchor
            {
                guard let imageName = imageAnchor.referenceImage.name else { return }
                let entity: ModelEntity = retriever(name: imageName, imageAnchor: imageAnchor)
                let anchor = AnchorEntity(anchor: imageAnchor)
                
                // 把影片加在imageAnchor上
                anchor.addChild(entity)
                parent.imageTrackingView.scene.addAnchor(anchor)
                
            }
            
            // TODO: 建Firebase後台來存取影片
            
        }
        
        func retriever(name: String, imageAnchor: ARImageAnchor) -> ModelEntity
        {
            var entity = ModelEntity()
            
            switch name
            {
                case "iOSClub2":
                    
                    // 指派影片
                    let path = Bundle.main.path(forResource: "second", ofType: "mp4")
                      
                    // 這邊是設定讓影片跑完之後可以重複播放
                    let videoURL = URL(fileURLWithPath: path!)
                    let playerItem = AVPlayerItem(url: videoURL)
                    videoPlayer = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
                    let videoMaterial = VideoMaterial(avPlayer: queuePlayer)

                    // 設定播放影片的大小
                    let width: Float = Float(imageAnchor.referenceImage.physicalSize.width * 1) // 1 or 1.03
                    let height: Float = Float(imageAnchor.referenceImage.physicalSize.height * 1)

                    // 改變播放影片的大小、外觀
                    entity = ModelEntity(mesh: .generatePlane(width: width, depth: height, cornerRadius: 0.3), materials: [videoMaterial])
                    
                    
                case "kris":
                    
                    // 指派影片
                    let path = Bundle.main.path(forResource: "kris", ofType: "mp4")
                    
                    // 這邊是設定讓影片跑完之後可以重複播放
                    let videoURL = URL(fileURLWithPath: path!)
                    let playerItem = AVPlayerItem(url: videoURL)
                    videoPlayer = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
                    let videoMaterial = VideoMaterial(avPlayer: queuePlayer)

                    // 設定播放影片的大小
                    let width: Float = Float(imageAnchor.referenceImage.physicalSize.width) // or * 1.03
                    let height: Float = Float(imageAnchor.referenceImage.physicalSize.height)

                    // 改變播放影片的大小、外觀
                    entity = ModelEntity(mesh: .generatePlane(width: width, depth: height, cornerRadius: 0.3), materials: [videoMaterial])
                    
                default:
                    break
            }
            
            // 回傳指定的entity
            return entity
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor])
        {
            
        }
        
        
        // 追蹤當前狀態
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor])
        {
            // imageAncor代表當前追蹤的照片
            guard let imageAnchor = anchors.first as? ARImageAnchor else {
                print("Problems loading anchor.")
                return
            }
            
            
            // 當鏡頭移開影片時，停止播放跟繼續播放
            if imageAnchor.isTracked
            {
                queuePlayer.play()
            }
            else
            {
                queuePlayer.pause()
                
                // 移除之前的anchor，這樣切換不同照片時，才能播放不同影片，功力不夠，所以只能用isTracked來作為邏輯分段點
                parent.imageTrackingView.session.remove(anchor: imageAnchor)
                
            }
        }
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
#endif
