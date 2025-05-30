//
//  SettingsView.swift
//  Fugu15
//
//  Created by Ghh on 02.01.2025.
//

import SwiftUI
import Foundation
import SwiftXPC
import KRW


//let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//let vers = ProcessInfo.processInfo.operatingSystemVersion
//
//
//private var defaults: UserDefaults? = nil
//public func defs() -> UserDefaults {
//    if defaults == nil {
//        let defaultsPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].path + "/Preferences/de.pinauten.Fugu15-Rootful.plist"
//        defaults = UserDefaults.init(suiteName: defaultsPath)
//    }
//    return defaults!
//}
//
//
//func tweaksEnabled() -> Bool {
//    if access(documentsDirectory.appendingPathComponent(".tweaks_disabled").path, F_OK) == 0 {
//        return false
//    } else {
//        return true
//    }
//}
//
//func isJailbroken() -> Bool {
//    if access("/Library/.installed_Fugu15_Rootful", F_OK) == 0 {
//        return true
//    } else {
//        return false
//    }
//}
//
//func setTweaksEnabled(_ enabled: Bool) {
//    if enabled {
//        try? FileManager.default.removeItem(atPath: documentsDirectory.appendingPathComponent(".tweaks_disabled").path)
//    } else {
//        FileManager.default.createFile(atPath: documentsDirectory.appendingPathComponent(".tweaks_disabled").path, contents: nil)
//    }
//}

struct SettingsView: View {
    @State private var enable_tweaks: Bool = tweaksEnabled()
    @State private var is_jb: Bool = isJailbroken()
    @State private var showAlert: Bool = false
    @AppStorage("kexploit", store: defs()) var kexploit: String = ""
    @AppStorage("puaf_method", store: defs()) var puafMethod: String = ""
    
    
    var body: some View {
        VStack {
            Text("Fugu15 Preferences")
                .font(.largeTitle)
                .padding()

            
            Toggle(isOn: $enable_tweaks) {
                Text(enable_tweaks ? "Tweaks enabled" : "Tweaks disabled")
            }
            .padding()
            .disabled(isJailbroken())
            .onChange(of: enable_tweaks) { newValue in
                setTweaksEnabled(enable_tweaks)
                if is_jb {
                    showAlert = true
                }
            }
            
            
            Text("Kernel exploit")
                .font(.title3)

            Picker("Kernel exploit", selection: $kexploit) {
                Text("weightBufs")
                    .foregroundColor(.black)
                    .tag("weightBufs")
                var tfp0: mach_port_t = 0
                if task_for_pid(mach_task_self_, 0, &tfp0) == KERN_SUCCESS {
                    Text("tfp0")
                        .foregroundColor(.black)
                        .tag("tfp0")
                }
                if vers.majorVersion >= 15 && vers.minorVersion <= 2 {
                    Text("mcbc")
                        .foregroundColor(.black)
                        .tag("mcbc")
                }
                Text("kfd")
                    .foregroundColor(.black)
                    .tag("kfd")
            }
            .pickerStyle(.segmented)
            .colorMultiply(.white)
            .padding()
            Spacer().frame(height: 20)
            if kexploit == "kfd" {
                Picker("puaf method", selection: $puafMethod) {
                    Text("puaf_smith")
                        .foregroundColor(.black)
                        .tag("puaf_smith")
                    Text("puaf_physpuppet")
                        .foregroundColor(.black)
                        .tag("puaf_physpuppet")
                }
                .colorMultiply(.white)
                .pickerStyle(.segmented)
                .padding()
            }
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
