import SwiftUI
import Firebase

struct CountTimer: View {
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var startTime: Date = Date()
    @State private var pauseTime: Date = Date()
    @State private var isPaused: Bool = true
    @State var showMemoView: Bool = false
    @State private var selectedPost: Post? = nil
    @State var posts: [Post] = []
    @State private var timerRunning: Bool = false
    let postID: String
    let postTitle: String
    let userID: String = AuthManager.shared.user?.uid ?? ""
    let icon: String
    @State var count = 0
    private let databaseRef = Database.database().reference()
    
    var formattedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) / 60 % 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("")
                Spacer()
                Picker(selection: $selectedPost, label: Text("Select a post")
                    .foregroundColor(Color.white)
                    
                    ) {
                    ForEach(posts) { post in
                        if post.userID == userID || post.userID == "all"
                        {
                            Text(post.title)
                                .font(.system(size: 20))
                                .tag(post as Post?)
                                .foregroundColor(.black)
                        }
                        }.accentColor(.white)
                }
                    .font(.system(size: 30))
                    .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(.white.opacity(3), lineWidth: 3)
                    
                ).accentColor(.white)
                .disabled(timerRunning)
                Spacer()
            }
            .padding()
            .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
            .foregroundColor(.white)

            Text(formattedTime)
                .font(.system(size: 40, design: .monospaced))
                //.padding()
            
            HStack {
                HStack{
                    Spacer()
                    Button(action: start) {
                        Text("スタート")
                    }
                    .disabled(timer != nil || !isPostValid(post: selectedPost))
                    .padding(.vertical,10)
                    .padding(.horizontal,25)
                    .font(.headline)
                    .foregroundColor(.white)
                    .background(timer != nil ? RoundedRectangle(cornerRadius: 25).fill(Color.gray) : RoundedRectangle(cornerRadius: 25).fill(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0)))
                                            
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: 20)
                HStack{
                    Spacer()
                    Button(action: pause) {
                        Text("ストップ")
                    }
                    .disabled(isPaused)
                    .padding(.vertical,10)
                    .padding(.horizontal,25)
                    .font(.headline)
                    .foregroundColor(.white)
                    .background(isPaused ? RoundedRectangle(cornerRadius: 25).fill(Color.gray): RoundedRectangle(cornerRadius: 25).fill(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0)))
                    Spacer()
                }
                //.padding()
            }
            .frame(maxWidth: .infinity, maxHeight: 20)
            .padding(.bottom)
            HStack {
                HStack {
                    Spacer()
                    Button(action: reset) {
                        Text("リセット")
                    }
                    .disabled(timer == nil && elapsedTime == 0)
                    .padding(.vertical,10)
                    .padding(.horizontal,25)
                    .font(.headline)
                    .foregroundColor(.white)
                    .background(timer == nil && elapsedTime == 0 ? RoundedRectangle(cornerRadius: 25).fill(Color.gray): RoundedRectangle(cornerRadius: 25).fill(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0)))
                    Spacer()
                }
                HStack{
                    Spacer()
                    Button(action: {
                        pause()
                        self.showMemoView = true
                    }, label: {
                        Text("完了")
                    })
                    .disabled(selectedPost == nil || timer == nil)
                    .frame(width:70,height:20)
                    .padding(.vertical,10)
                    .padding(.horizontal,25)
                    .font(.headline)
                    .foregroundColor(.white)
                    .background(isPaused ? RoundedRectangle(cornerRadius: 25).fill(Color.gray): RoundedRectangle(cornerRadius: 25).fill(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0)))
                    .fullScreenCover(isPresented: $showMemoView) {
                        if let selectedPost = selectedPost {
                            MemoView(postID: selectedPost.id, postTitle: selectedPost.title, icon: selectedPost.icon, elapsedTime: elapsedTime)
                                .onDisappear {
                                    reset()
                                }
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
              databaseRef.child("Posts").observe(.value) { snapshot in
                  var newPosts: [Post] = []
                  for child in snapshot.children {
                      if let snapshot = child as? DataSnapshot,
                         let post = Post(snapshot: snapshot) {
                          newPosts.append(post)
                      }
                  }
                  posts = newPosts.sorted(by: { $0.createdAt > $1.createdAt })

                  // 選択されている投稿がまだ設定されていない場合に限り、最も古い投稿を設定します。
                  if selectedPost == nil {
                      selectedPost = getNewPost(posts: posts)
                  }
              }
          }
    }
    
    private func start() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isPaused {
                pauseTime = Date()
                isPaused = false
            }
            elapsedTime += Date().timeIntervalSince(pauseTime)
            pauseTime = Date()
        }
        timerRunning = true
    }
    
    private func pause() {
        timer?.invalidate()
        timer = nil
        isPaused = true
    }
    
    private func reset() {
        pause()
        elapsedTime = 0
        timerRunning = false
    }
    
    func getNewPost(posts: [Post]) -> Post? {
        return posts.sorted(by: { $0.createdAt > $1.createdAt }).first(where: { $0.userID == userID || $0.userID == "all" })
    }
    
    func isPostValid(post: Post?) -> Bool {
        guard let post = post else { return false }
        return post.userID == userID || post.userID == "all"
    }

}

struct CountTimer_Previews: PreviewProvider {
    static var previews: some View {
        CountTimer(postID: "test", postTitle: "test", icon: "test")
    }
}
