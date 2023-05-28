import SwiftUI

struct HelpView: View {
    @State private var isSheetPresented = false
    
    var body: some View {
        ZStack{
            Image(systemName: "circle.fill")
                .cornerRadius(30.0)
                .font(.system(size: 40))
                .foregroundColor(.white)
            VStack {
                Button(action: {
                    self.isSheetPresented = true
                }, label:  {
                    Image(systemName: "questionmark.circle")
                    
                        .foregroundColor(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
                    //.foregroundColor(.black)
                    //.background(Color.blue)
                        .cornerRadius(30.0)
                    
                        .font(.system(size: 40)) // --- 4
                    
                })
                
                
                //.shadow(color: Color(.black).opacity(0.2), radius: 8, x: 0, y: 4)
                .sheet(isPresented: $isSheetPresented, content: {
                    SwipeableView()
                    
                })
            }
        }
    }
}

struct SwipeableView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                FirstView()
                    .tag(0)
                SecondView()
                    .tag(1)
                ThirdView()
                    .tag(2)
                FourthView()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle())
            
            
            CustomPageIndicator(numberOfPages: 4, currentPage: $selectedTab)
                .padding(.bottom)
        }
    }
}

struct CustomPageIndicator: View {
    var numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.primary : Color.gray)
                    .frame(width: 10, height: 10)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct FirstView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack{
            HStack{
                Button(action:{
                    presentationMode.wrappedValue.dismiss()
                }){
                    Text("閉じる")
                }
                .padding()
                Spacer()
                Text("チュートリアル")
                Spacer()
                Text("")
                Spacer()
            }
            .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
            .foregroundColor(.white)
            Spacer()
            Image("チュートリアル１")
                .resizable()
                .scaledToFit()
            Spacer()
            VStack{
                Text("画面右下にあるプラスボタンをクリックしてください。")
                Text("「積み上げ目標」、「アイコン」、そして「目標時間」を入力してください。")
                Text("全ての内容を入力し終わったら、画面右上の投稿ボタンをクリックして目標を追加します。")
            }.padding()
                .padding(.bottom,20)
            }
    }
}


struct SecondView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack{
            HStack{
                Button(action:{
                    presentationMode.wrappedValue.dismiss()
                }){
                    Text("閉じる")
                }
                .padding()
                Spacer()
                Text("チュートリアル")
                Spacer()
                Text("")
                Spacer()
            }
            .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
            .foregroundColor(.white)
            Spacer()
            Image("チュートリアル２")
                .resizable()
                .scaledToFit()
                .padding()
            Spacer()
            Text("画面上部のプルダウンから、先ほど追加した目標を選択してください。")
                .padding()
                .padding(.bottom,10)
        }
    }
}

struct ThirdView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack{
            HStack{
                Button(action:{
                    presentationMode.wrappedValue.dismiss()
                }){
                    Text("閉じる")
                }
                .padding()
                Spacer()
                Text("チュートリアル")
                Spacer()
                Text("")
                Spacer()
            }
            .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
            .foregroundColor(.white)
            Spacer()
            Image("チュートリアル３")
                .resizable()
                .scaledToFit()
                .padding()
            Spacer()
            VStack{
                Text(" 目標が選択されたら、スタートボタンをクリックして記録を開始します。")
                Text("  カウントアップタイマーで記録が終わったら、完了ボタンをクリックしてください。")
            }.padding()
                .padding(.bottom,10)
        }
    }
}

struct FourthView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack{
            HStack{
                Button(action:{
                    presentationMode.wrappedValue.dismiss()
                }){
                    Text("閉じる")
                }
                .padding()
                Spacer()
                Text("チュートリアル")
                Spacer()
                Text("")
                Spacer()
            }
            .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
            .foregroundColor(.white)
            Spacer()
            VStack{
                Image("チュートリアル４")
                    .resizable()
                    .scaledToFit()
                //.frame(width: 500, height: 500)
                
            }
            .padding(.top,40)
            Spacer()
            VStack{
                Text("現在の目標に対する合計記録時間と今回の記録時間が表示されます。")
                Text("もし記録に関するメモがあれば、入力してください。最後に、戻るボタンをクリックして積み上げ記録の追加を完了させます。")
            }
            .padding()
            .padding(.bottom,10)
        }
    }
}


struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
