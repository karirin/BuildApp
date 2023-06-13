import SwiftUI
import Firebase

struct MemoView: View {
    @State private var memoText = ""
    var postID: String
    let userID: String = AuthManager.shared.user?.uid ?? ""
    var postTitle: String
    var icon: String
    var elapsedTime: TimeInterval
    @State private var timePostTitle: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var totalElapsedTime: TimeInterval = 0
    
    init(postID: String, postTitle: String, icon: String, elapsedTime: TimeInterval) {
        self.postID = postID
        self.postTitle = postTitle
        self.icon = icon
        self.elapsedTime = elapsedTime
    }
    
    var body: some View {
        HStack{
            Button(action: {
                saveTimerValueToDatabase()
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("戻る")
            })
            .padding()
            Spacer()
            Text("積み上げ記録を追加する")
            Spacer()
            Text("test")
                .opacity(0) // 透明度を0にして、見えないようにする
                .padding(.trailing)
        }
        .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
        .foregroundColor(.white)
        Spacer()
        VStack {
            Spacer()
            VStack{
                HStack{
                    Text(timePostTitle) // ここで timePostTitle を表示します
                        .font(.title)
                        .padding()
                    Spacer()
                } // Postのタイトル
                
                VStack(alignment: .leading){
                    Text("合計時間").font(.system(size: 35))
                    Text(timeString(from: totalElapsedTime))
                        .font(.system(size: 30))
                    //Text("00時00分00秒").font(.system(size: 30))
                    HStack {
                        Spacer() // これを追加してください。
                        Image(systemName: "plus")
                        Text(timeString(from: elapsedTime))
                    }.font(.system(size: 30))
                }
                .padding(20) //合計時間

            }
            VStack{
                TextField("メモを入力してください", text: $memoText)
                    .padding()
            }
            Spacer()
            Text("")
            Spacer()
            Text("")
            Spacer()
        }
        .onAppear {
            fetchTotalTimeForPost { totalTime in
                DispatchQueue.main.async {
                    self.totalElapsedTime = totalTime
                }
            }
        }
    }
    
    
    func saveTimerValueToDatabase() {
        let database = Database.database().reference()
        let timesRef = database.child("times")
        let newTimeRef = timesRef.childByAutoId()
        let postRef = database.child("Posts").child(postID)
        let elapsedTimeRoundedDown = floor(elapsedTime)
        
        postRef.observeSingleEvent(of: .value) { snapshot in
            guard let post = snapshot.value as? [String: Any] else { return }
            let icon = post["icon"] as? String ?? "a.square.fill"
            let time_val = ["text": "commentText",
                            "icon": icon,
                            "body": memoText,
                            "time": elapsedTimeRoundedDown,
                            "postTitle": postTitle,
                            "postID": postID,
                            "userID": userID,
                            "createdAt": Date().timeIntervalSince1970] as [String: Any]
            
            newTimeRef.setValue(time_val) { error, _ in
                if let error = error {
                    print(error.localizedDescription)
                    print(elapsedTimeRoundedDown)
                } else {
                    print("記録されました")
                    print(elapsedTimeRoundedDown)
                }
            }
        }
    }
}

extension MemoView {
    func timeString(from seconds: TimeInterval) -> String {
        let totalSeconds = Int(floor(seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d時%d分%d秒", hours, minutes, remainingSeconds)
        } else if minutes > 0 {
            return String(format: "%d分%d秒", minutes, remainingSeconds)
        } else {
            return String(format: "%d秒", remainingSeconds)
        }
    }
    
    func fetchTotalTimeForPost(completion: @escaping (TimeInterval) -> Void) {
        let database = Database.database().reference()
        let timesRef = database.child("times")
        
        timesRef.observeSingleEvent(of: .value) { snapshot in
            guard let times = snapshot.value as? [String: [String: Any]] else {
                completion(0)
                return
            }
            
            var totalTime: TimeInterval = 0
            
            for time in times.values {
                if let postIDForTime = time["postID"] as? String, postIDForTime == postID {
                    totalTime += time["time"] as? TimeInterval ?? 0
                    
                    // time.postTitle を取得し、timePostTitle に保存します
                    if let postTitleForTime = time["postTitle"] as? String {
                        self.timePostTitle = postTitleForTime
                    }
                }
            }
            
            completion(totalTime)
        }
    }
    
}

struct MemoView_Previews: PreviewProvider {
    static var previews: some View {
        MemoView(postID: "postID", postTitle: "postTitle", icon: "icon", elapsedTime: 123)
    }
}
