//
//  ContentView.swift
//  Fugu15
//
//  Created by Linus Henze.
//

import SwiftUI

#if os(iOS)
import UIKit
#else
import AppKit
#endif

//import Fugu15KernelExploit

//struct ContentView: View {
//    @State var logText = ""
//    @State private var showingRemoveFrame = RemoveFuguInstall.shouldShow()
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Divider()
//
//                TabView {
//                    JailbreakView(logText: $logText)
//                        .tabItem {
//                            Label("Jailbreak", systemImage: "lock.open")
//                        }
//
//                    LogView(logText: $logText)
//                        .tabItem {
//                            Label("Log", systemImage: "keyboard.macwindow")
//                        }
//
//                    AboutView()
//                        .tabItem {
//                            Label("About", systemImage: "questionmark.app.dashed")
//                        }
//                    SettingsView()
//                        .tabItem {
//                            Label("Settings", systemImage: "gear")
//                        }
//                }
//                    .sheet(isPresented: $showingRemoveFrame) {
//                        RemoveFuguInstall(isPresented: $showingRemoveFrame)
//                    }
//                    .navigationTitle("Fugu15")
//                    .navigationBarTitleDisplayMode(.inline)
//            }
//        }.navigationViewStyle(.stack)
//    }
//}
func getKernelVersion() -> String? {
    var mib = [CTL_KERN, KERN_VERSION]
    var size = 0
    
    // 1. Получаем размер данных
    if sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) != 0 {
        return nil
    }
    
    // 2. Выделяем буфер и получаем данные
    var version = [CChar](repeating: 0, count: size)
    if sysctl(&mib, u_int(mib.count), &version, &size, nil, 0) != 0 {
        return nil
    }
    
    return String(cString: version)
}



struct ContentView: View {
    @State private var isJailbroken = false
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var logMessages: [String] = [
        "[*] Starting exploit...",
        "[*] Checking environment...",
        "[*] Found vulnerable CVE-2022-26706",
        "[*] Bypassing AMFI protections...",
        "[*] This is a very long message that should wrap to multiple lines instead of being truncated",
        "[*] Mounting root filesystem as read/write",
        "[*] Installing bootstrap...",
        "[*] Creating symlinks...",
        "[*] Patchin dyld_shared_cache...",
        "[*] Finalizing installation...",
        "[*] Jailbreak completed successfully!"
    ]
    func log() {
        for _ in 0...100 {
            logMessages.append("Hello")
        }
            
    }
    var body: some View {
        ZStack {
            // Основной интерфейс
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                // Статус-бар
                HStack {
                    Button(action: { withAnimation(.spring()) { showSettings.toggle() } }) {
                        Image(systemName: "gear")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    Spacer()

                    Button(action: { withAnimation(.spring()) { showHelp.toggle() } }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 10)


                Text("unc0ver jailbreak")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)

                Text("for iOS 11.0 - 14.8")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)

                Text("by @pwn20wnd & @sbinger")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("UI by @iOS_App_Dev & @HiMyNameIsUbik")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)

                Text(isJailbroken ? "Jailbroken" : "0/32")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isJailbroken ? .green : .white)

                Button(action: {
                    isJailbroken.toggle()
                    log()
                    
                }) {
                    Text(isJailbroken ? "Already jailbroken" : "Jailbreak")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(isJailbroken ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isJailbroken)
                .padding(.vertical, 20)
                
                VStack(alignment: .leading, spacing: 6) {
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(logMessages.indices, id: \.self) { index in
                                    Text(logMessages[index])
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true) // Перенос строк
                                        .id(index) // Для автоматической прокрутки
                                }
                            }
                            .padding()
                            .onChange(of: logMessages.count) { _ in
                                // Автопрокрутка к последнему сообщению
                                withAnimation {
                                    proxy.scrollTo(logMessages.count - 1, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(8)
                    .frame(height: 200) // Фиксированная высота для области прокрутки
                    .padding(.horizontal, 20)
                }
                Text("Version: 1.0-a32")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 10)
            }
            .blur(radius: showSettings || showHelp ? 4 : 0)
            .disabled(showSettings || showHelp)

            if showSettings {
                SettingsPanel()
                    .transition(.move(edge: .leading))
                    .zIndex(1)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width < -100 {
                                    withAnimation(.spring()) {
                                        showSettings = false
                                    }
                                }
                            }
                    )
            }

            // Панель помощи (выезжает справа)
            if showHelp {
                HelpPanel()
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width > 100 {
                                    withAnimation(.spring()) {
                                        showHelp = false
                                    }
                                }
                            }
                    )
            }
        }
    }
}

struct SettingsPanel: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemGray6)

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Spacer()

//                    Button(action: {}) {
//                        Image(systemName: "xmark")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
                }
                .padding()

                // Пример настроек
                SettingRow(icon: "moon.fill", title: "Dark Mode", isOn: true)
                SettingRow(icon: "bell.fill", title: "Notifications", isOn: false)
                SettingRow(icon: "lock.fill", title: "Security", isOn: true)

                Spacer()
            }

            .padding(.top, 50)
        }
//        .frame(width: UIScreen.main.bounds.width * 0.8)
    }
}

struct HelpPanel: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemGray6)

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Help")
                        .font(.largeTitle.bold())
                        .foregroundColor(.cyan)


//                    Button(action: {}) {
//                        Image(systemName: "xmark")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    ScrollView {
                        Color(.systemGray3)
                        VStack(alignment: .leading){
                            
                            Text("What to do after jailbreak?")
                                .font(.system(size: 18, weight: .heavy))
                                
                            Text("- As this is a developer jailbreak - install Filza for trollstore, make a symlink /var/jb/usr/bin/dpkg-deb pointing to /usr/bin/dpkg and then install a sileo package manager")
                                .font(.system(size: 18, weight: .regular))
                        }
                        
                    }
                    
                }
                .padding()
                

                // Пример помощи
                

                Spacer()
            }
            .padding(.top, 50)
        }
//        .frame(width: UIScreen.main.bounds.width * 0.8)
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    @State var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)

            Text(title)
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
    }
}

struct HelpRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Spacer()

            Text(text)
                .foregroundColor(.white)

            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 30)
        }
        .padding(.horizontal)
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
