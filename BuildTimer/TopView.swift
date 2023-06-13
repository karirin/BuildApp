import SwiftUI
import FirebaseDatabase
import UIKit
import GoogleMobileAds

struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner) // インスタンスを生成
        // 諸々の設定をしていく
        banner.adUnitID = "ca-app-pub-4898800212808837~3192676251" // 自身の広告IDに置き換える
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner // 最終的にインスタンスを返す
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {
      // 特にないのでメソッドだけ用意
    }
}

struct TopView: View {
    var body: some View {
        VStack {
            
                AdMobBannerView()
                    .frame(height:50)
                TabView {
                    ZStack {
                        PostListView()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.97, opacity: 1.0))
                        
                        VStack {
                            HStack {
                                Spacer()
                                HelpView()
                                    .padding(.trailing, 10)
                            }
                            Spacer()
                        }
                    }
                    .tabItem {
                        Image(systemName: "house")
                        Text("ホーム")
                    }
                    
                    ZStack {
                        TimeView(postID: "all", postTitle: "test")
                            .background(Color(red: 0.95, green: 0.95, blue: 0.97, opacity: 1.0))
                        
                        VStack {
                            HStack {
                                Spacer()
                                HelpView()
                                    .padding(.trailing, 10)
                            }
                            Spacer()
                        }
                    }
                    .tabItem {
                        Image(systemName: "timer")
                        Text("積み上げ記録")
                    }
                    
                    ZStack {
                        PieView()
                            .background(Color(red: 0.95, green: 0.95, blue: 0.97, opacity: 1.0))
                        
                        VStack {
                            HStack {
                                Spacer()
                                HelpView()
                                    .padding(.trailing, 10)
                            }
                            Spacer()
                        }
                    }
                    .tabItem {
                        Image(systemName: "chart.xyaxis.line")
                        Text("グラフ")
                    }
                    
                    SettingsView()
                        .background(Color(red: 0.95, green: 0.95, blue: 0.97, opacity: 1.0))
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("設定")
                        }
                }
        }
    }

    fileprivate struct AnotherView: View {
        
        var textContent: String
        
        var body: some View {
            
            Text(textContent)
            
        }
    }
}

struct TopView_Previews: PreviewProvider {
    static var previews: some View {
        TopView()
    }
}
