//
//  PostListView.swift
//  BuildApp
//
//  Created by hashimo ryoya on 2023/04/17.
//

import SwiftUI
import Firebase
import Combine
import StoreKit

struct Post: Identifiable, Hashable {
    var id: String// = UUID().uuidString
    var icon: String
    var title: String
    var goalHours: Int
    var body: String
    var createdAt: Date
    var userID: String
    
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: Any],
              let title = value["title"] as? String,
              let goalHours = value["goalHours"] as? Int,
              let body = value["body"] as? String,
              let createdAt = value["createdAt"] as? TimeInterval,
              let userID = value["userID"] as? String,
              let icon = value["icon"] as? String,
              let id = value["id"] as? String else {
            return nil
        }
        
        self.id = id
        self.title = title
        self.goalHours = goalHours
        self.body = body
        self.createdAt = Date(timeIntervalSince1970: createdAt)
        self.userID = userID
        self.icon = icon
    }
}

class TimeData: ObservableObject {
    @Published var totalTime: [String: Int] = [:]
}

class PostsViewModel: ObservableObject {
    @Published var posts: [Post] = []
    var userID: String = AuthManager.shared.user?.uid ?? ""
    private let databaseRef = Database.database().reference()
    private var cancellable: AnyCancellable?


    init() {
        fetchPosts()
        cancellable = AuthManager.shared.$user
            .sink(receiveValue: { [weak self] user in
                self?.userID = user?.uid ?? ""
            })
    }
    
    private func fetchPosts() {
        databaseRef.child("Posts").observe(.value) { snapshot in
            var newPosts: [Post] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let post = Post(snapshot: snapshot) {
                    newPosts.append(post)
                }
            }
            DispatchQueue.main.async {
                self.posts = newPosts.sorted(by: { $0.createdAt > $1.createdAt })
            }
        }
    }
    deinit {
        cancellable?.cancel()
    }
}

struct PostListView: View {
    @State var posts: [Post] = []
    @State var postText = ""
    @State var body_text = ""
    @State var icon = ""
    @State var goalHours = 1
    @State var showAnotherView: Bool = false
    @State var showAnotherView_post: Bool = false
    @State private var selection_post = ""
    @State private var progressValue = 0.0
    @State var timeUsed: TimeInterval = 0
    @State private var selectedPost: Post?
    @StateObject private var timeData = TimeData()
    @State static var dummyShowAnotherView = false
    let userID: String = AuthManager.shared.user?.uid ?? ""
    private let databaseRef = Database.database().reference()
    @State var ShowNextView = false
    @StateObject private var viewModel = PostsViewModel()
    var body: some View {
        
//        VStack{
//            Text("Build App")
//        }.frame(maxWidth:.infinity).background(.blue)
        NavigationView {
            VStack{
                CountTimer(postID: "test", postTitle: "test", icon: "test")
                ScrollView(.vertical, showsIndicators: false){
                    ForEach(viewModel.posts) { post in
                        if post.userID == viewModel.userID || post.userID == "all" {
                            NavigationLink(
                                destination: AnotherView(postID: post.id,postTitle: post.title).background(Color(red: 0.95, green: 0.95, blue: 0.97, opacity: 1.0)),
                                label: {
                                    ZStack {
                                        //                                    Color(.quaternarySystemFill)
                                        //                                        .cornerRadius(24)
                                        Color(.systemGray6)
                                            .cornerRadius(24)
                                            .shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 4)
                                        //  .shadow(color: Color(.black).opacity(1), radius: 8, x: 5, y: 20) // ここに.shadow()を追加
                                        VStack{
                                            HStack{
                                                Image(systemName: "\(post.icon)")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width:30,height:30)
                                                    .padding()
                                                    //.foregroundColor(.blue)
                                                VStack{
                                                    HStack{
                                                        Text(post.title)      .font(.system(size: 24))
                                                        Spacer()
                                                        Spacer()
                                                    }
                                                    HStack{
                                                        Text("目標積み上げ時間：\(post.goalHours)時間")
                                                            .font(.system(size: 18))
                                                        Spacer()
                                                    }
                                                }
                                                //Spacer()
                                            }.padding(5)
                                            HStack{
                                                Text("\(Int(ceil(Double(timeData.totalTime[post.id] ?? 0)/3600)))時間 / \(post.goalHours)時間")
                                                    .font(.system(size: 18))
                                                Spacer()
                                            }.padding(.leading)
                                            
                                            let progress = progressValue(for: post)
                                            ProgressView(value: progress)
                                                .progressViewStyle(CustomProgressViewStyle())
                                                .onAppear(perform: {
                                                    
                                                }).frame(maxWidth: .infinity, maxHeight: 20)
                                                .padding(.bottom).padding(.horizontal)
                                        }.frame(maxWidth: .infinity, maxHeight: 200)
                                            .background(.white)
                                            .cornerRadius(24)
                                        
                                    }.padding()
                                        .accentColor(Color(red: 0.35, green: 0.35, blue: 0.35, opacity: 1))
                                })
                        }
                    }
                    Spacer()
                        .onAppear {
                            promptForReview()
                            databaseRef.child("Posts").observe(.value) { snapshot in
                                var newPosts: [Post] = []
                                for child in snapshot.children {
                                    if let snapshot = child as? DataSnapshot,
                                       let post = Post(snapshot: snapshot) {
                                        newPosts.append(post)
                                    }
                                }
                                posts = newPosts.sorted(by: { $0.createdAt > $1.createdAt })
                                selectedPost = getOldestPost(posts: posts)
                            }
                            databaseRef.child("times").observe(.value) { snapshot in
                                var newTotalTime: [String: Int] = [:]
                                for child in snapshot.children {
                                    if let snapshot = child as? DataSnapshot,
                                       let time = Time(snapshot: snapshot) {
                                        if newTotalTime[time.postID] == nil {
                                            newTotalTime[time.postID] = 0
                                        }
                                        newTotalTime[time.postID]! += time.time
                                    }
                                }
                                timeData.totalTime = newTotalTime
                                //print("Updated totalTime: \(timeData.totalTime)") // デバッグ情報を表示
                            }
                        }

                }.background(Color(red: 0.95, green: 0.95, blue: 0.97, opacity: 1.0))
                    .frame(width: UIScreen.main.bounds.width)
                //            .navigationBarTitle("積み上げリスト", displayMode: .inline)
                    .overlay(
                        ZStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack{
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            self.showAnotherView_post = true
                                        }, label: {
                                            Image(systemName: "plus")
                                                .foregroundColor(.white)
                                                .font(.system(size: 24)) // --- 4
                                        }).frame(width: 60, height: 60)
                                            .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
                                            .cornerRadius(30.0)
                                            .shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 4)
                                            .sheet(isPresented: $showAnotherView_post, content: {
                                                
                                                PostAdd(showAnotherView_post: PostListView.$dummyShowAnotherView)
                                            })
                                            .padding()
                                    }
                                }
                            }
                        }
                    )
            }.background(Color(red: 0.95, green: 0.95, blue: 0.97, opacity: 1.0))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    func promptForReview() {
        let launchCount = UserDefaults.standard.integer(forKey: "launchCount") + 1
        UserDefaults.standard.set(launchCount, forKey: "launchCount")
        
        if launchCount % 5 == 0 {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
    
    private func progressValue(for post: Post) -> Double {
        guard let totalTimeForPost = timeData.totalTime[post.id] else {
            return 0.0
        }
        
        Text("\(Double(totalTimeForPost / 3600))")
        
        return Double(totalTimeForPost) / Double(post.goalHours * 3600)
    }
    
    func getOldestPost(posts: [Post]) -> Post? {
        return posts.sorted(by: { $0.createdAt < $1.createdAt }).first
    }
}




fileprivate struct AnotherView: View {
    
    var postID: String
    var postTitle: String
    
    var body: some View {
        TimeView(postID: postID,postTitle: postTitle, isHStackVisible: false)
            
        //PrivacyView()
    }
    
}

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .scaleEffect(x: 1, y: 4, anchor: .center) // ここでy値を変更して、ProgressViewの高さを調整します。
            .padding(.vertical)
            .accentColor(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
    }
}


struct nextView: View {
    @Environment(\.dismiss) private var dismiss
    var postID: String
    var postTitle: String
    
    var body: some View {
        NavigationView {
            TimeView(postID: postID,postTitle: postTitle)
                .navigationTitle("コメント一覧")
                .navigationBarItems(leading: Button("戻る", action: { dismiss() }))
        }
    }
}

struct PostListView_Previews: PreviewProvider {
    static var previews: some View {
        PostListView()
    }
}
