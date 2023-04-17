//
//  ContentView.swift
//  Messagebot
//
//  Created by Gautam Ramesh on 4/11/23.
//

import SwiftUI

struct MyArrayElement: Decodable {
    let stringValue: String?
    let intValue: Int?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self.stringValue = stringValue
            self.intValue = nil
        } else if let intValue = try? container.decode(Int.self) {
            self.stringValue = nil
            self.intValue = intValue
        } else {
            throw DecodingError.typeMismatch(MyArrayElement.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid type"))
        }
    }
}

struct MessageData: Codable {
    var text: String
    var fromMe: Bool
    let id = UUID()
}

struct GeneratedMessage: Decodable {
    var text: String
}

struct MessageToSend: Codable {
    var text: String
    var to: String
}

class MessageStore: ObservableObject {
//    @Published var tabMessages = ["1": [
//        MessageData(text: "Hey! Have you made any plans for the weekend?", fromMe: true),
//        MessageData(text: "Not yet. Why do you ask?", fromMe: false),
//        MessageData(text: "I was thinking of taking a trip to the beach. Would you be interested in joining me?", fromMe: true),
//        MessageData(text: "That sounds like fun! When were you thinking of going?", fromMe: false),
//        MessageData(text: "I was thinking of leaving on Saturday morning and coming back on Sunday evening. Does that work for you?", fromMe: true),
//        MessageData(text: "Yeah, I'm free this weekend. Let's do it!", fromMe: false),
//        MessageData(text: "Awesome! I'll start looking for accommodations. Do you have any preferences?", fromMe: true),
//        MessageData(text: "Not really. As long as it's close to the beach, I'm happy.", fromMe: false),
//        MessageData(text: "Alright, I'll keep that in mind. Do you want to take a car or a train?", fromMe: true),
//        MessageData(text: "I don't mind either way. What do you think?", fromMe: false)
//      ]
//    ]
    @Published var tabMessages = [String: [MessageData]]()
    
    func addMessage(selectedTab: String, message: String) {
        tabMessages[selectedTab]?.append(MessageData(text: message, fromMe: true))
    }
    
    func addConversation(phoneNumber: String) {
        let url = URL(string: "http://127.0.0.1:5000/get_messages?number=\(phoneNumber)&num_messages=10")

        let request = URLRequest(url: url!)

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in

            print(response!)

            if let data = data, let messages = try? JSONDecoder().decode([[MyArrayElement]].self, from: data) {
                let messagesText = messages.map { MessageData(text: $0[1].stringValue ?? "", fromMe: $0[5].intValue!  == 1) }
                self.tabMessages.updateValue(messagesText, forKey: phoneNumber)
                print(messagesText)
            } else {
                print("couldn't decode data")
            }
        })

        task.resume()
        
//        let messagesText = [
//            MessageData(text: "Hey! Have you made any plans for the weekend?", fromMe: false),
//            MessageData(text: "Not yet. Why do you ask?", fromMe: true),
//            MessageData(text: "I was thinking of taking a trip to the beach. Would you be interested in joining me?", fromMe: false),
//            MessageData(text: "That sounds like fun! When were you thinking of going?", fromMe: true),
//            MessageData(text: "I was thinking of leaving on Saturday morning and coming back on Sunday evening. Does that work for you?", fromMe: false),
//            MessageData(text: "Yeah, I'm free this weekend. Let's do it!", fromMe: true),
//            MessageData(text: "Awesome! I'll start looking for accommodations. Do you have any preferences?", fromMe: false),
//            MessageData(text: "Not really. As long as it's close to the beach, I'm happy.", fromMe: true),
//            MessageData(text: "Alright, I'll keep that in mind. Do you want to take a car or a train?", fromMe: false),
//          ]
//
//        self.tabMessages.updateValue(messagesText, forKey: phoneNumber)
    }

}

struct ContentView: View {
    @State private var selectedTab = "1"
    
    @ObservedObject var messageStore = MessageStore()
    
    var buttonLabels: [String] {
        Array(messageStore.tabMessages.keys)
    }
    
    var messages: [MessageData] {
        messageStore.tabMessages[selectedTab] ?? []
    }
    
    var body: some View {
        NavigationView {
            Sidebar(buttonLabels: buttonLabels, selectedTab: $selectedTab, messageStore: messageStore)

            ChatScreenView(messages: messages, selectedTab: $selectedTab, messageStore: messageStore)
                .navigationTitle("Messagebot")
        }
    }
}

func formatPhoneNumber(number: String) -> String {
    if number.count == 10 {
        let areaCode = number.prefix(3)
        let mid = number.prefix(6).suffix(3)
        let ending = number.suffix(4)
        return "(\(areaCode)) \(mid)-\(ending)"
    } else {
        return number
    }
}

struct Sidebar: View {
    var buttonLabels: [String]
    @Binding var selectedTab: String
    @State private var inputText = ""
    
    var messageStore: MessageStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Phone Number", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 10)
                    .padding(.trailing, 5)
                
                Button("Open") {
                    messageStore.addConversation(phoneNumber: inputText)
                }
                .padding(.leading, 5)
                .padding(.trailing, 10)
            }
            
            Divider().padding(.top, 10)

            ForEach(buttonLabels, id: \.self) { label in
                Button(action: {
                    selectedTab = label
                }) {
                    Text(formatPhoneNumber(number: label))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedTab == label ? Color.white: Color.black)
                        .padding(.vertical)
                }
                .buttonStyle(PlainButtonStyle())
                .background(selectedTab == label ? Color.blue : Color.clear)
                
                Divider()
            }
            
            Spacer()
        }
    }
}

struct ChatScreenView: View {
    var messages: [MessageData]
    @Binding var selectedTab: String
    @State private var newMessage = ""
    
    var messageStore: MessageStore
    
    func generate() {
        let url = URL(string: "http://127.0.0.1:5000/generate_message")

        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonData = try? JSONEncoder().encode(messages)
        request.httpBody = jsonData

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in

            if let data = data, let decodedMessage = try? JSONDecoder().decode(GeneratedMessage.self, from: data) {
                newMessage = decodedMessage.text
            } else {
                print("couldn't decode data")
            }
        })

        task.resume()
//        sleep(1)
//        newMessage = "I don't mind either way."
    }
    
    func send() {
        let url = URL(string: "http://127.0.0.1:5000/send")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try? JSONEncoder().encode(MessageToSend(text: newMessage, to: selectedTab))
        request.httpBody = jsonData
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
        })
        
        task.resume()
        
        newMessage = ""
    }

    var body: some View {
        VStack {
            List(messages, id: \.id) { message in
                ZStack {
                    if message.fromMe {
                        // Align to the right if message is from the user
                        HStack {
                            Spacer()
                            Text(message.text)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .foregroundColor(.white)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    } else {
                        // Align to the left if message is from someone else
                        HStack {
                            Text(message.text)
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .foregroundColor(.black)
                                .background(Color.gray)
                                .cornerRadius(10)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }

            HStack {
                Button("↻") {
                    messageStore.addConversation(phoneNumber: selectedTab)
                }
                
                Button("Generate") {
                    generate()
                }
                
                TextField("Enter a new message", text: $newMessage)
                
                Button("Send") {
                    messageStore.addMessage(selectedTab: selectedTab, message: newMessage)
                    
//                    newMessage = ""
                    send()
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
    }
}
