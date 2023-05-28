import SwiftUI
import Firebase
import FirebaseDatabase

enum TimePeriod: String, CaseIterable, Identifiable {
    case day = "日"
    case week = "週"
    case month = "月"
    case year = "年"
    
    var id: String { self.rawValue }
}

struct PieChartView: View {
    @ObservedObject var viewModel: PieChartViewModel
    
    var body: some View {
        //        VStack{
        //            Text("Build App")
        //        }.frame(maxWidth:.infinity).background(.blue)
        GeometryReader { geometry in
            ZStack {
                ForEach(viewModel.segments) { segment in
                    PieChartSegmentView(segment: segment, chartSize: geometry.size, postTitle: segment.postTitle)
                    // postTitle を渡す
                }
            }
        }.animation(.easeInOut(duration: 0.5))
    }
}

struct PieChartSegmentView: View {
    var segment: PieChartViewModel.Segment
    var chartSize: CGSize
    var postTitle: String
    
    private var radius: CGFloat {
        min(chartSize.width, chartSize.height) * 0.5
    }
    
    private var startAngle: Angle {
        Angle(degrees: segment.startAngle)
    }
    
    private var endAngle: Angle {
        Angle(degrees: segment.endAngle)
    }
    
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: chartSize.center)
                path.addArc(center: chartSize.center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.closeSubpath()
            }
            //.fill(segment.color)
            .fill(LinearGradient(gradient: Gradient(colors: [segment.color, segment.color.opacity(0.8)]), startPoint: .leading, endPoint: .trailing))
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            // ここでセグメントの角度範囲を計算してフォントサイズを調整
            let angleRange = endAngle.degrees - startAngle.degrees
            let fontSize = min(max(angleRange * 0.15, 10), 20)

            Text(postTitle) // 追加
                .foregroundColor(.black)
                .font(.system(size: CGFloat(fontSize), weight: .bold)) // フォントサイズを動的に調整
                .position(chartSize.center)
                .offset(x: radius * CGFloat(cos((startAngle.degrees + endAngle.degrees) * 0.5 * Double.pi / 180)) * 0.5,
                        y: radius * CGFloat(sin((startAngle.degrees + endAngle.degrees) * 0.5 * Double.pi / 180)) * 0.5)

        }
    }
}

class PieChartViewModel: ObservableObject {
    @Published var segments: [Segment] = []
    let userID: String = AuthManager.shared.user?.uid ?? ""
    var ref: DatabaseReference!
    
    init() {
        ref = Database.database().reference()
        fetchData()
    }
    
    func fetchData(for period: TimePeriod = .day) {
        ref.child("times").observeSingleEvent(of: .value) { (snapshot, error) in
            var times: [Time] = []
            
            for child in (snapshot as! DataSnapshot).children {
                if let childSnapshot = child as? DataSnapshot,
                   let time = Time(snapshot: childSnapshot) {
                    times.append(time)
                }
            }
            
            let now = Date()
            let filteredTimes = times.filter { time in
                // ログイン中のユーザーIDとTime.userIDが一致するかを確認
                guard time.userID == self.userID || time.userID == "all" else { return false }
                
                switch period {
                case .day:
                    return Calendar.current.isDate(time.createdAt, inSameDayAs: now)
                case .week:
                    return Calendar.current.dateComponents([.weekOfYear], from: time.createdAt, to: now).weekOfYear == 0
                case .month:
                    return Calendar.current.dateComponents([.month], from: time.createdAt, to: now).month == 0
                case .year:
                    return Calendar.current.dateComponents([.year], from: time.createdAt, to: now).year == 0
                }
            }
            
            self.process(filteredTimes, for: period)
        }
    }

    
    private func process(_ times: [Time], for period: TimePeriod) {
        let totalDuration = times.reduce(0) { result, time in
            result + time.time
        }
        let groupedTimes = Dictionary(grouping: times, by: { $0.postID })
        //print(groupedTimes) //timeのデータ
        var startAngle = 0.0
        segments = groupedTimes.map {
            (postID, times) -> Segment in
            let duration = times.reduce(0) { result, time in
                result + time.time
            }
            let proportion = Double(duration) / Double(totalDuration)
            let endAngle = startAngle + proportion * 360.0
            let postTitle = times.first?.postTitle ?? "Unknown" // タイトルを取得（存在しない場合は "Unknown"）
            let segment = Segment(startAngle: startAngle, endAngle: endAngle, color: Color.random(), postTitle: postTitle) // postTitle を渡す
            startAngle = endAngle
            return segment
        }
    }
    
    struct Segment: Identifiable {
        var id = UUID()
        var startAngle: Double
        var endAngle: Double
        var color: Color
        var postTitle: String
    }
}

extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

extension CGSize {
    var center: CGPoint {
        CGPoint(x: width * 0.5, y: height * 0.5)
    }
}

extension Color {
    static func random() -> Color {
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        return Color(red: red, green: green, blue: blue)
    }
}

struct PieChart_Previews: PreviewProvider {
    static var previews: some View {
        PieView()
    }
}

struct PieView: View {
    @State private var selectedPeriod = TimePeriod.month
    @StateObject private var viewModel = PieChartViewModel()
    @State private var totalTime: TimeInterval = 0
    @State private var totalTimePerPost: [String: TimeInterval] = [:]
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(formatDate(for: selectedPeriod))
                Spacer()
            }
            .padding()
            .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
            .foregroundColor(.white)
            Picker("期間", selection: $selectedPeriod.onChange { newPeriod in
                viewModel.fetchData(for: newPeriod)
                updateTotalTime(for: newPeriod)
            }) {
                ForEach(TimePeriod.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            PieChartView(viewModel: viewModel)
            //.padding()
                .frame(width: 280, height: 280)
            Spacer()
            ScrollView(.vertical, showsIndicators: false){
                VStack {
                    ForEach(totalTimePerPost.keys.sorted(), id: \.self) { postID in
                        HStack {
                            VStack{
                                HStack{
//                                    Image(systemName: "square.fill")
//                                        .frame(width:10)
//                                        .font(.system(size: 34))
                                    Text("\(postID)")
                                        .font(.system(size: 24))
                                        //.fontWeight(.bold)
                                    Spacer()
                                }
                                HStack{
                                    Image(systemName: "stopwatch.fill")
                                        .font(.system(size: 20))
                                        //.background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
                                        .foregroundColor(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
                                    Text("合計時間 ")         .font(.system(size: 22))
                                    Spacer()
                                    Text("\(formattedDuration(totalTimePerPost[postID] ?? 0))")
                                        .font(.system(size: 22))
                                    //Spacer()
                                }
                                
                            }.padding(.horizontal)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }.frame(maxWidth: .infinity)
                .padding(.top)
            
            
            // 合計時間の表示
            //            HStack {
            //                Text("合計時間: ")
            //                Text("\(totalTime, specifier: "%.2f") 分")
            //            }
               // .padding()
            
        }
        .onAppear {
            viewModel.fetchData(for: selectedPeriod)
            updateTotalTime(for: selectedPeriod)
        }
        
    }
    
    func formatDate(for period: TimePeriod) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        let now = Date()
        
        switch period {
        case .day:
            dateFormatter.dateFormat = "yyyy年M月d日"
        case .week:
            dateFormatter.dateFormat = "yyyy年M月d日"
            let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)!
            return dateFormatter.string(from: startOfWeek) + " 〜 " + dateFormatter.string(from: endOfWeek)
        case .month:
            dateFormatter.dateFormat = "yyyy年M月"
        case .year:
            dateFormatter.dateFormat = "yyyy年"
        }
        
        return dateFormatter.string(from: now)
    }
    
    func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        var formattedString = ""
        
        if hours > 0 {
            formattedString += "\(hours)時"
        }
        
        if minutes > 0 {
            if !formattedString.isEmpty {
                formattedString += " "
            }
            formattedString += "\(minutes)分"
        }
        
        if seconds > 0 {
            if !formattedString.isEmpty {
                formattedString += " "
            }
            formattedString += "\(seconds)秒"
        }
        
        return formattedString
    }

    
    // 合計時間をtime.postID別に取得するために変更
    func updateTotalTime(for period: TimePeriod) {
        viewModel.ref.child("times").observeSingleEvent(of: .value) { snapshot in
            var times: [Time] = []
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let time = Time(snapshot: childSnapshot) {
                    times.append(time)
                }
            }
            
            let now = Date()
            let filteredTimes = times.filter { time in
                guard time.userID == viewModel.userID || time.userID == "all" else { return false }
                switch period {
                case .day:
                    return Calendar.current.isDate(time.createdAt, inSameDayAs: now)
                case .week:
                    return Calendar.current.dateComponents([.weekOfYear], from: time.createdAt, to: now).weekOfYear == 0
                case .month:
                    return Calendar.current.dateComponents([.month], from: time.createdAt, to: now).month == 0
                case .year:
                    return Calendar.current.dateComponents([.year], from: time.createdAt, to: now).year == 0
                }
            }
            
            totalTimePerPost = [:] // リセット
            for time in filteredTimes {
                let duration = TimeInterval(time.time) // 秒単位に変換
                if let existingDuration = totalTimePerPost[time.postTitle] {
                    totalTimePerPost[time.postTitle] = existingDuration + duration
                } else {
                    totalTimePerPost[time.postTitle] = duration
                }
            }
        }
    }
}
