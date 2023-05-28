//
//  PostAdd.swift
//  BuildApp
//
//  Created by hashimo ryoya on 2023/04/26.
//

import SwiftUI
import Firebase

struct IconInfo: Identifiable {
    let id = UUID()
    let name: String
    let systemImageName: String
}

struct PostAdd: View {
    @State var posts: [Post] = []
    @State var postText = ""
    @State var body_text = ""
    @State var icon = ""
    @State var goalHours = 1
    @State var showAnotherView: Bool = false
    @State private var selection_post = ""
    @State var timeUsed: TimeInterval = 0
    @State private var selectedPost: Post?
    @StateObject private var timeData = TimeData()
    @State private var selectedIcon: IconInfo?
    @Binding var showAnotherView_post: Bool
    @State private var progressValue = 1.0
    @Environment(\.presentationMode) var presentationMode
    private let databaseRef = Database.database().reference()
    let userID: String = AuthManager.shared.user?.uid ?? ""
    let iconList = [
        IconInfo(name: "携帯", systemImageName: "iphone.gen1"),
        IconInfo(name: "ノートパソコン", systemImageName: "laptopcomputer"),
        IconInfo(name: "運動", systemImageName: "figure.run"),
        IconInfo(name: "読書", systemImageName: "book"),
        IconInfo(name: "ショッピング", systemImageName: "cart"),
        IconInfo(name: "カフェ", systemImageName: "mug"),
        IconInfo(name: "料理", systemImageName: "fork.knife"),
        IconInfo(name: "その他", systemImageName: "questionmark"),
    ]
    var body: some View {
        HStack{
            Button(action:{
                self.presentationMode.wrappedValue.dismiss() // この行を修正
            }){
                Text("閉じる")
            }
            .padding()
            Spacer()
            Text("積み上げ目標を追加する")
            Spacer()
            Button(action:{ addPost()
                self.showAnotherView_post = false // この行を追加
                self.presentationMode.wrappedValue.dismiss()
            }){
                Text("投稿する")
            }
            .padding()
        } //閉じるボタンと投稿する
        //.padding()
        .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
        .foregroundColor(.white)
        Spacer()
        VStack{
            HStack{
                Text("積み上げ目標を入力してください")
                    .font(.system(size: 20))
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
            }
            TextField("例：ランニング、読書", text: $postText)
                .frame(maxWidth: .infinity)
                .border(Color.clear, width: 0)
            
        }.padding()
        Spacer()
        VStack{
            HStack{
                Text("アイコンを選択してください")
                    .font(.system(size: 20))
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.leading)
                Spacer()
            }
            //ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 69))]) {
                ForEach(iconList) { icon in
                    VStack {
                        //Text(icon.name)
                        
                        Image(systemName: icon.systemImageName)
                            .font(.system(size: 40))
                            .foregroundColor(selectedIcon?.id == icon.id ? .blue : .black)
                            .onTapGesture {
                                selectedIcon = icon
                            }
                    }
                    .foregroundColor(selectedIcon?.id == icon.id ? .blue : .black)
                    //.padding()
                }
            }
        } //アイコンを選択してください
        
        Spacer()
        VStack{
            HStack{
                Text("目標時間を設定してください")
                    .font(.system(size: 20))
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.leading)
                    
                Spacer()
            }
            Text("\(Int(progressValue)) 時間")
                .font(.title3)
                .padding(.top)
                .fontWeight(.bold)
                .fontWeight(.heavy)
            Slider(value: $progressValue, in: 1...100, step: 1)
                .padding(.horizontal)
            //目標を設定してください
            VStack{
                HStack{
                    Text("目標時間の目安")
                        .padding(.bottom)
                    Spacer()
                }
                HStack{
                    Text("2週間の期間で、1日に2時間行う場合、")
                    Spacer()
                }
                HStack{
                    Text("合計で2時間 × 14日 = 28時間となります。")
                    Spacer()
                }
            }
            .padding()
        }
        Spacer()
    }
    
    func fetchPosts() {
        databaseRef.child("Posts").observe(.childAdded) { snapshot in
            if let post = Post(snapshot: snapshot) {
                DispatchQueue.main.async {
                    self.posts.append(post)
                    self.posts.sort(by: { $0.createdAt > $1.createdAt })
                }
            }
        }
    }
    
    func addPost() {
        let databaseRef = Database.database().reference()
        let postRef = databaseRef.child("Posts").childByAutoId()
        let post = ["id": postRef.key!,
                    "title": postText,
                    "icon": selectedIcon?.systemImageName ?? "", // ここも修正
                    "body": body_text,
                    "goalHours": Int(progressValue),
                    "userID": userID,
                    "createdAt": Date().timeIntervalSince1970] as [String : Any]
        postRef.setValue(post) { error, _ in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("コメントが投稿されました")
                postText=""
                selection_post = ""
                goalHours = 1
                fetchPosts() 
            }
        }
    }
}

struct PostAdd_Previews: PreviewProvider {
    @State static private var dummyShowAnotherView = false
    
    static var previews: some View {
        PostAdd(showAnotherView_post: $dummyShowAnotherView)
    }
}

