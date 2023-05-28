//
//  TimeView.swift
//  BuildApp
//
//  Created by hashimo ryoya on 2023/04/21.
//

import SwiftUI
import Firebase
import Combine

struct Time: Identifiable {
    var id: String = UUID().uuidString
    var icon: String
    var text: String
    var postTitle: String
    var postID: String
    var userID: String
    var createdAt: Date
    var time: Int
    var body: String

    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: Any],
              let icon = value["icon"] as? String,
              let text = value["text"] as? String,
              let postID = value["postID"] as? String,
              let postTitle = value["postTitle"] as? String,
              let createdAt = value["createdAt"] as? TimeInterval,
              let userID = value["userID"] as? String,
              let body = value["body"] as? String,
              let time = value["time"] as? Int else {
            return nil
        }

        self.text = text
        self.icon = icon
        self.postID = postID
        self.postTitle = postTitle
        self.createdAt = Date(timeIntervalSince1970: createdAt)
        self.userID = userID
        self.time = time
        self.body = body
    }
}

struct PostIdentifier: Hashable, Comparable {
    let postID: String
    let postTitle: String
    
    static func < (lhs: PostIdentifier, rhs: PostIdentifier) -> Bool {
        return lhs.postID < rhs.postID
    }
}

struct TimeView: View {
    //@StateObject var timerManager = TimerManager()
    @State var times: [Time] = []
    @State var showAnotherView_time: Bool = false
    @State var timeText = ""
    let postID: String
    let postTitle: String
    let userID: String = AuthManager.shared.user?.uid ?? ""
    @State private var currentDate: Date = Date()
    let calendar = Calendar.current
    @State private var pageIndex: Int = 0
    @State private var periodSelection: Int = 0
    @Environment(\.dismiss) private var dismiss
    var isHStackVisible: Bool = true
    
    private let databaseRef = Database.database().reference()
    
    var body: some View {
        VStack {
            if isHStackVisible {
                HStack {
                    Spacer()
                    Text("\(dateStringForPeriod(periodSelection, for: currentDate))")

                    Spacer()
                }
                .padding()
                .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
                .foregroundColor(.white)
            }else{
                HStack {
                    Button("戻る", action: { dismiss() })
                        .padding(.leading)
                    
                    Spacer()
                    
                    Text("\(dateStringForPeriod(periodSelection, for: currentDate))")

                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    Button("戻る", action: { dismiss() })
                        .opacity(0) // 透明度を0にして、見えないようにする
                        .padding(.trailing)
                }
                .padding()
                .background(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
                .foregroundColor(.white)

            }
            Picker(selection: $periodSelection, label: Text("表示期間")) {
                Text("日").tag(0)
                Text("週").tag(1)
                Text("月").tag(2)
                Text("年").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom)
            TabView(selection: $pageIndex) {
                ForEach(rangeForPeriod, id: \.self) { index in
                    dateScrollView(index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onAppear {
                observeTimes()
            }
            .onChange(of: pageIndex, perform: { value in
                currentDate = calendar.date(byAdding: periodComponent, value: value, to: Date()) ?? Date()
            })
        }
        .navigationBarTitleDisplayMode(isHStackVisible ? .inline : .large)
                .navigationBarBackButtonHidden(!isHStackVisible)
    }
              
                private func dateScrollView(index: Int) -> some View {
                    let date = calendar.date(byAdding: periodComponent, value: index, to: Date()) ?? Date()
                    let groupedTimes = filteredTimes(for: date)
                    //print("インデックス: \(index), グループ化されたtimes: \(groupedTimes), date: \(date)")
                    //print("\(groupedTimes)")
                    
                    return ScrollView(.vertical, showsIndicators: false) {
                        VStack {
                            ForEach(groupedTimes.keys.sorted(), id: \.self) { postIdentifier in
                                VStack {
                                    //Text("\(postIdentifier.postTitle)")
                                    HStack{
                                        Text(postIdentifier.postTitle)
                                            .font(.title)
                                            .fontWeight(.light)
                                            .padding(.horizontal)
                                        Spacer()
                                    }
                                        ForEach(groupedTimes[postIdentifier]!, id: \.id) { time in
                                            if time.userID == userID || time.userID == "all" {
                                HStack{
                                    Image(systemName: "\(time.icon)")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(.white)
                                        .frame(width:30,height:30)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(red: 0.2, green: 0.68, blue: 0.9, opacity: 1.0))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white, lineWidth: 0)
                                        )
                                    
                                    VStack() {
                                        HStack{
                                            Text(" \(formattedTime(seconds: time.time))").font(.title3)
                                        Spacer()
                                        }
                                                //.font(.title2)
                                        if !time.body.isEmpty {
                                            HStack{
                                                Text("\(time.body)")
                                                    .padding(.leading,5)
                                                Spacer()
                                            }
                                            }
                                    }
                                    //.frame(maxWidth: .infinity, alignment: .leading)
                                    Spacer()
                                    
                                    Text(customDateFormatter.string(from: time.createdAt))
                                        .frame(maxHeight: .infinity, alignment: .leading)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 40)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: 80)
                            }
                        }
                    }
                }
            
            }
            .padding(.bottom)
        }
        .padding(.bottom)
        //.overlay(totalTimeForEachDay(date: date, period: periodSelection))
        .frame(width: UIScreen.main.bounds.width)
    }
    
    private let customDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
    
    private var periodComponent: Calendar.Component {
        switch periodSelection {
        case 1:
            return .weekOfYear
        case 2:
            return .month
        case 3:
            return .year
        default:
            return .day
        }
    }
    
    private var rangeForPeriod: ClosedRange<Int> {
        switch periodSelection {
        case 1:
            return -4...4
        case 2:
            return -12...12
        case 3:
            return -5...5
        default:
            return -30...30
        }
    }
    
    private func filteredTimes(for date: Date) -> [PostIdentifier: [Time]] {
        let startOfPeriod = calendar.dateInterval(of: periodComponent, for: date)?.start ?? Date()
        let endOfPeriod = calendar.date(byAdding: periodComponent, value: 1, to: startOfPeriod) ?? Date()

        print("デバッグ: startOfPeriod: \(startOfPeriod), endOfPeriod: \(endOfPeriod)")

        let filteredTimes = times.filter { time in
            time.createdAt >= startOfPeriod && time.createdAt < endOfPeriod
        }

        print("デバッグ: filteredTimes: \(filteredTimes)")
        
        var groupedTimes: [PostIdentifier: [Time]] = [:]
        for time in filteredTimes {
            let identifier = PostIdentifier(postID: time.postID, postTitle: time.postTitle)
            //print("日付: \(date), フィルタリングされたtimes: \(filteredTimes), startOfPeriod: \(startOfPeriod), endOfPeriod: \(endOfPeriod)")
            groupedTimes[identifier, default: []].append(time)
        }
        
        return groupedTimes
    }


    private func dateFormatterForPeriod(_ period: Int) -> DateFormatter {
        let formatter = DateFormatter()
        switch period {
        case 2:
            formatter.dateFormat = "yyyy/MM"
        case 3:
            formatter.dateFormat = "yyyy"
        default:
            formatter.dateFormat = "yyyy/MM/dd"
        }
        return formatter
    }

    private func dateStringForPeriod(_ period: Int, for date: Date) -> String {
        let startOfPeriod = calendar.dateInterval(of: periodComponent, for: date)?.start ?? Date()
        let endOfPeriod = calendar.date(byAdding: periodComponent, value: 1, to: startOfPeriod) ?? Date()

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP") // 日本語のロケールを設定
        formatter.dateFormat = "yyyy年M月d日"

        switch period {
        case 1: // 週の場合
            let endDate = calendar.date(byAdding: .day, value: -1, to: endOfPeriod) ?? Date()
            return formatter.string(from: startOfPeriod) + "〜" + formatter.string(from: endDate)
        case 2: // 月の場合
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: startOfPeriod)
        case 3: // 年の場合
            formatter.dateFormat = "yyyy年"
            return formatter.string(from: startOfPeriod)
        default: // 日の場合
            return formatter.string(from: startOfPeriod)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private func formattedTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        var formattedString = ""
        if hours > 0 {
            formattedString += "\(hours)時間"
        }
        if minutes > 0 {
            formattedString += "\(minutes)分"
        }
        if remainingSeconds > 0 {
            formattedString += "\(remainingSeconds)秒"
        }
        
        return formattedString
    }
    
    private func observeTimes() {
        let timesRef = databaseRef.child("times")
        timesRef.observe(.value) { snapshot in
            var newTimes: [Time] = []
            var timesByPostID: [String: [Time]] = [:]
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let time = Time(snapshot: snapshot) {
                    if postID == "all" {
                        if time.userID == self.userID || time.userID == "all"{
                            newTimes.append(time)
                            timesByPostID[time.postID, default: []].append(time)
                        }
                    } else if time.postID == self.postID {
                        newTimes.append(time)
                    }
                }
            }
            times = newTimes.sorted(by: { $0.createdAt > $1.createdAt })

            for (postID, postTimes) in timesByPostID {
                timesByPostID[postID] = postTimes.sorted(by: { $0.createdAt > $1.createdAt })
            }
        }
    }


}

struct TimeView_Previews: PreviewProvider {
    static var previews: some View {
        TimeView(postID: "all",postTitle: "test")
    }
}
