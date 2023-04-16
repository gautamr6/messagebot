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
    @Published var tabMessages = ["1": [MessageData(text: "Hi there!", fromMe: false), MessageData(text: "How are you?", fromMe: true)], "2": [MessageData(text: "Hello!", fromMe: false), MessageData(text: "I'm good. How are you?", fromMe: true), MessageData(text: "Great!", fromMe: false)]]
    
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
                    Text("\(label)")
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
                    send()
                }
                .disabled(newMessage.isEmpty)
            }
            .padding()
        }
    }
}
