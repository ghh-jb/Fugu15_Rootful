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
import KRW
import iDownload
import SwiftXPC
import MachO


let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let vers = ProcessInfo.processInfo.operatingSystemVersion


private var defaults: UserDefaults? = nil
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

var jbDone = false

enum JBStatus {
    case notStarted
    case unsupported
    case inProgress
    case failed
    case done
    
    func text() -> String {
        switch self {
        case .notStarted:
            return "Jailbreak"
            
        case .unsupported:
            return "Unsupported"
            
        case .inProgress:
            return "Jailbreaking..."
            
        case .failed:
            return "Error!"
            
        case .done:
            return "Jailbroken"
        }
    }
    
    func color() -> Color {
        switch self {
        case .notStarted:
            return .accentColor
            
        case .unsupported:
            return .accentColor
            
        case .inProgress:
            return .accentColor
            
        case .failed:
            return .red
            
        case .done:
            return .green
        }
    }
}

// idevice stats
private func cpuMarketingName(code: String) -> String {
    if code == "T6031" {
       return "Apple M3 Max"
    } else if code == "T6030" {
       return "Apple M3 Pro"
    } else if code == "T8122" {
       return "Apple M3"
    } else if code == "T8130" {
       return "Apple A17 Pro"
    } else if code == "T8120" {
       return "Apple A16 Bionic"
    } else if code == "T6022" {
       return "Apple M2 Ultra"
    } else if code == "T6021" {
       return "Apple M2 Max"
    } else if code == "T6020" {
       return "Apple M2 Pro"
    } else if code == "T8112" {
       return "Apple M2"
    } else if code == "T8110" {
       return "Apple A15 Bionic"
    } else if code == "T6002" {
       return "Apple M1 Ultra"
    } else if code == "T6001" {
       return "Apple M1 Max"
    } else if code == "T6000" {
       return "Apple M1 Pro"
    } else if code == "T8103" {
       return "Apple M1"
    } else if code == "T8101" {
       return "Apple A14 Bionic"
    } else if code == "T8030" {
       return "Apple A13 Bionic"
    } else if code == "T8027" {
       return "Apple A12X Bionic"
    } else if code == "T8020" {
       return "Apple A12 Bionic"
    } else {
       return "Uncknown CPU, create PR"
    }
}
func uname() -> (sysname: String,nodename: String,release: String,version: String,machine: String){
        var systemInfo = utsname()
        let result = Darwin.uname(&systemInfo)

        repeat {
            guard result == 0 else {
                break
            }

            guard let sysname = withUnsafePointer(to: &systemInfo.sysname, {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String(validatingUTF8: ptr)
                }
            }) else {
                break
            }

            guard let nodename = withUnsafePointer(to: &systemInfo.nodename, {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String(validatingUTF8: ptr)
                }
            }) else {
                break
            }

            guard let release = withUnsafePointer(to: &systemInfo.release, {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String(validatingUTF8: ptr)
                }
            }) else {
                break
            }

            guard let version = withUnsafePointer(to: &systemInfo.version, {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String(validatingUTF8: ptr)
                }
            }) else {
                break
            }

            guard let machine = withUnsafePointer(to: &systemInfo.machine, {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String(validatingUTF8: ptr)
                }
            }) else {
                break
            }

            return (sysname, nodename, release, version, machine)
        } while false

        return ("", "", "", "", "")
    }

func getCPU() -> String {
    let cpuCode = uname().version.components(separatedBy: "_").last
    return String(format: "%@ (%@)", cpuMarketingName(code: cpuCode!), cpuCode!)
}

func getKernelVersion() -> String? {
    var mib = [CTL_KERN, KERN_VERSION]
    var size = 0
    
    if sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) != 0 {
        return nil
    }
    
    var version = [CChar](repeating: 0, count: size)
    if sysctl(&mib, u_int(mib.count), &version, &size, nil, 0) != 0 {
        return nil
    }
    
    return String(cString: version)
}

func getMachineName() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
}

func getModelId() -> String {
        let name: String
        var mib = [CTL_HW, HW_MODEL]

        // Max model name size not defined by sysctl. Instead we use io_name_t
        // via I/O Kit which can also get the model name
        var size = MemoryLayout<io_name_t>.size

        let ptr = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        let result = sysctl(&mib, u_int(mib.count), ptr, &size, nil, 0)

        if result == 0 { name = String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self)) }
        else { name = String() }

        ptr.deallocate()

        #if DEBUG
            if result != 0 {
                print("ERROR - \(#file):\(#function) - errno = "
                    + "\(result)")
            }
        #endif

        return name
    }
func getProcessorInfo() -> [CChar] {
    var size = 0
    sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
    return machine
}


struct ContentView: View {
    @State private var isJailbroken = false
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showHelp = false
    @State private var logMessages: [String] = [
        "[+] Fugu15_Rootful in not for sale",
        "[+] If you purshased Fugu15_Rootful, please report the seller",
        "[+] get source code at https://github.com/ghh-jb/Fugu15_Rootful",
        "[+] Machine Name: \(getMachineName())",
        "[+] Model Name: \(getModelId())",
        "[+] Hostname: \(UIDevice.current.name)",
        "[+] Kernel Version: \(getKernelVersion()!)",
        "[+] Processor version: \(getCPU())",
        "[+] Kernel page size: 0x\(String(getpagesize(), radix: 16))",
        "[+] System Version: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    ]
    
    @State var status: JBStatus = .notStarted
    @State var textStatus1      = "Status: Not running"
    @State var textStatus2      = ""
    @State var textStatus3      = ""
    @State var showSuccessMsg   = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button(action: { withAnimation(.spring()) { showSettings.toggle() } }) {
                        Image(systemName: "gear")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Spacer()
                    
                    VStack {
                        Button(action: { withAnimation(.spring()) { showHelp.toggle() } }) {
                            Image(systemName: "command")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Button(action: { withAnimation(.spring()) { showAbout.toggle() } }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)


                Text("Fugu15_Rootful")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)

                Text("for iOS 15.0 - 15.4.1")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)

                Text("by @LinusHenze (Linus Henze) & @ghh-jb (untether)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("UI by @ghh-jb (untether)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text("Original UI by @LinusHenze (Linus Henze)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)


                Button(action: {
                    isJailbroken.toggle()
                    status = .inProgress
                    
                    DispatchQueue(label: "Fugu15").async {
                        launchExploit()
                    }
                    
                }) {
                    Text(status.text())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(status.color())
                        .cornerRadius(10)
                }.alert(isPresented: $showSuccessMsg) {
                    Alert(title: Text("Success"), message: Text("All exploits succeded and iDownload is now running on port 1337!"), dismissButton: .default(Text("Reboot Userspace"), action: {
                        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15 && ProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 2 {
                            restoreRealCreds()
                        }
                        
                        var servicePort: mach_port_t = 0
                        let kr = bootstrap_look_up(bootstrap_port, "jb-global-stashd", &servicePort)
                        guard kr == KERN_SUCCESS else {
                            return
                        }
                        
                        // Init PAC bypass in process
                        let pipe = XPCPipe(port: servicePort)
                        _ = pipe.send(message: ["action": "userspaceReboot"])
                    }))
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
                                        .fixedSize(horizontal: false, vertical: true)
                                        .id(index)
                                        .padding(.horizontal, 25)
                                }
                            }
                            .onChange(of: logMessages.count) { _ in
                                
                                withAnimation {
                                    proxy.scrollTo(logMessages.count - 1, anchor: .bottom)
                                }
                            }
                            .padding(.vertical)
                            
                        }
                    }
                    .background(Color(white: 0.1))
                    .cornerRadius(8)
                    .frame(height: 200)
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
            
            if showAbout {
                AboutPanel()
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.width > 100 {
                                    withAnimation(.spring()) {
                                        showAbout = false
                                    }
                                }
                            }
                    )
            }

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
    
    func print(_ text: String, ender: String = "\n") {
        logMessages.append(text)
    }
    func launchExploit() {
        do {
            /*let krw = try Fugu15DKKRW(oobPCI: Bundle.main.bundleURL.appendingPathComponent("oobPCI")) { msg in
                if status != .done {
                    DispatchQueue.main.async {
                        if msg.hasPrefix("Status: ") {
                            statusUpdate(msg)
                        }
                        
                        print(msg)
                    }
                }
            }
            
            try iDownload.launch_iDownload(krw: iDownloadKRW(krw: krw))*/
            
            KRW.logger = { msg in
                if status != .done {
                    DispatchQueue.main.async {
                        print(msg)
                    }
                }
            }
            
            if access("/Library/.installed_Fugu15_Rootful", F_OK) == 0{
                KRW.logger("[#] Already jailbroken!")
                Ngenerator.notificationOccurred(.error)
                status = .done
                jbDone = true
                return
            }
                    
            try testkrwstuff()
            
            
            try iDownload.launch_iDownload(krw: KRW(), otherCmds: iDownloadCmds)
            
            DispatchQueue(label: "Waiter").async {
                while !jbDone {
                    usleep(1000)
                }
                
                DispatchQueue.main.async {
                    status = .done
                    showSuccessMsg = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                print("Fugu15 error: \(error)")
                status = .failed
            }
        }
    }
}

// settings
public func defs() -> UserDefaults {
    if defaults == nil {
        let defaultsPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].path + "/Preferences/de.pinauten.Fugu15-Rootful.plist"
        defaults = UserDefaults.init(suiteName: defaultsPath)
    }
    return defaults!
}


func tweaksEnabled() -> Bool {
    if access(documentsDirectory.appendingPathComponent(".tweaks_disabled").path, F_OK) == 0 {
        return false
    } else {
        return true
    }
}

func isJailbroken() -> Bool {
    if access("/Library/.installed_Fugu15_Rootful", F_OK) == 0 {
        return true
    } else {
        return false
    }
}

func setTweaksEnabled(_ enabled: Bool) {
    if enabled {
        try? FileManager.default.removeItem(atPath: documentsDirectory.appendingPathComponent(".tweaks_disabled").path)
    } else {
        FileManager.default.createFile(atPath: documentsDirectory.appendingPathComponent(".tweaks_disabled").path, contents: nil)
    }
}





struct SettingsPanel: View {
    @State private var enable_tweaks: Bool = tweaksEnabled()
    @State private var is_jb: Bool = isJailbroken()
    @State private var showAlert: Bool = false
    @AppStorage("kexploit", store: defs()) var kexploit: String = ""
    @AppStorage("puaf_method", store: defs()) var puafMethod: String = ""
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemGray6)

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Settings")
                        .font(.largeTitle.bold())
                        .foregroundColor(.accentColor)

                    Spacer()

//                    Button(action: {}) {
//                        Image(systemName: "xmark")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
                }
                .padding()
                
                Toggle(isOn: $enable_tweaks) {
                    HStack {
                        Text(enable_tweaks ? Image(systemName: "wrench.and.screwdriver.fill") : Image(systemName: "wrench.and.screwdriver"))
                        +
                        Text(enable_tweaks ? "Tweaks enabled" : "Tweaks disabled")
                    }
                }
                .padding()
                .disabled(isJailbroken())
                .onChange(of: enable_tweaks) { newValue in
                    setTweaksEnabled(enable_tweaks)
                }
                
                
                
                Text("Kernel exploit")
                    .font(.title3)
                    .padding()

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
//                Spacer().frame(height: 20)
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

            .padding(.top, 50)
        }
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
                        .foregroundColor(.accentColor)


//                    Button(action: {}) {
//                        Image(systemName: "xmark")
//                            .font(.title2)
//                            .foregroundColor(.white)
//                    }
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    ScrollView {
                        VStack(alignment: .leading){
                            
                            Divider()
                            
                            Text("I cant connect to SSH as in instruction on github, how to install package manager?")
                                .font(.system(size: 18, weight: .heavy))
                            Text("ghh-jb>>")
                                .font(.system(size: 18, weight: .regular))
                            Text("SSH is not included by default into rootFS bootstrap. You need a little bit hacky way to install it.")
                                .font(.system(size: 18, weight: .regular))
                            Text("1) Install Filza for trollstore")
                                .font(.system(size: 18, weight: .regular))
                            Text("2) Create a symlink /var/jb/usr/bin/dpkg-deb) pointing to the same location on rootFS (to /usr/bibn/dpkg)")
                                .font(.system(size: 18, weight: .regular))
                            Text("3) Download Sileo deb file from ios repo updates")
                                .font(.system(size: 18, weight: .regular))
                            Text("4) Share with Filza. Tap on it and tap \"install\"")
                                .font(.system(size: 18, weight: .regular))
                        }
                        Divider()
                        VStack(alignment: .leading) {
                            Text("I am getting tons of errors during initial package manager installation.")
                                .font(.system(size: 18, weight: .heavy))

                            Text("ghh-jb>>")
                                .font(.system(size: 18, weight: .regular))
                            Text("This is caused because rootFS bootstrap does not include core packages such as \"cy+cpu.arm64(e)\" or \"firmware\"")
                                .font(.system(size: 18, weight: .regular))
                            Text("You need to fix it manually by creating multiple empty debian packages providing theese dependencies")
                                .font(.system(size: 18, weight: .regular))
                            let debianSite = "https://www.debian.org/doc/debian-policy/ch-controlfields.html"
                            let lnk = "1) First read about control file architecture at [debian official website](\(debianSite))"
                            Text(.init(lnk))
                                .font(.system(size: 18, weight: .regular))
                            Text("2) Create simple control file with: ")
                                .font(.system(size: 18, weight: .regular))
                            Text("  Package: \"your missing core package\" (for example \"cy+cpu.arm64)\"")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            Text("  Version: \"your preferred version here\" (Important note: for firmware I recommend setting your real firmware version, for example \"15.2\")")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            Text("3) Other fields may contain anything you want")
                                .font(.system(size: 18, weight: .regular))
                            Text("4) As I remember the fixes should be: \"cy+cpu.arm64\", \"cy+cpu.arm64e\", \"cy+model.[iPhone/iPad]\", \"firmware\", and \"gsc.camera-flash\"")
                                .font(.system(size: 18, weight: .regular))
                        }
                        
                        
                        // todo:
                        /// add about  setuid bit
                        /// add about completely unsigned binaries
                        /// add about offsets
                        // ====
                        Divider()
                        VStack(alignment: .leading) {
                            Text("I cant use sudo and NewTerm crashing with \"session ended\" error.")
                                .font(.system(size: 18, weight: .heavy))
                            Text("ghh-jb>>")
                                .font(.system(size: 18, weight: .regular))
                            Text("This is again caused by faulty rootFS bootstrap")
                                .font(.system(size: 18, weight: .regular))
                            Text("Ownership of all directories in root is incorrect and permissions of some core files are wrong")
                                .font(.system(size: 18, weight: .regular))
                            Text("Open Filza for trollstore, open terminal in it (it has separate environment and does not have those problems)")
                                .font(.system(size: 18, weight: .regular))
                            Text("     Run the following commands:")
                                .font(.system(size: 18, weight: .semibold))
                            VStack(alignment: .leading) {
                                Text("     chown -R root:wheel /usr")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chown -R root:wheel /bin")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chown -R root:wheel /sbin")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chown -R root:wheel /Library")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chown -R root:wheel /Applications")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chown -R root:wheel /etc")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                            
                            Text("     After that run the following:")
                                .font(.system(size: 18, weight: .semibold))
                            
                            VStack(alignment: .leading) {
                                Text("     chmod 04755 /usr/bin/su")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chmod 04755 /usr/bin/sudo")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chmod 04755 /usr/bin/login")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chmod 04755 /usr/libexec/cydia/cydo (Note: If you have cydia installed)")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Text("     chmod 04755 /usr/libexec/installer/groot (Note: If you have Installer 5 installed)")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            }
                            
                            
                            
                        }
                        
                        
                    }
                    
                }
                .padding()
                

                

                Spacer()
            }
            .padding(.top, 50)
        }
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

struct AboutPanel: View {
    @Environment(\.openURL) var openURL
    
    @State private var descriptionMaxWidth: CGFloat?
    
    struct DescriptionWidthPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
            _ = libgrabkernel_version()
        }
    }
    
    var body: some View {

        ZStack(alignment: .center) {
            Color(.systemGray6)
            VStack {
                Image("FuguIcon")
                    .resizable()
                    .cornerRadius(22.37)
                    .padding()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.size.width/3)
                    .shadow(radius: 10)
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Fugu15 Jailbreak Tool")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundColor(.accentColor)
                            .background(
                                GeometryReader(content: { geometry in
                                    Color.clear.preference(
                                        key: DescriptionWidthPreferenceKey.self,
                                        value: geometry.size.width
                                    )
                                })
                            )
                            .padding(.bottom)
                        
                        Text("Fugu15_Rootful is an (incomplete) Jailbreak for iOS 15.0 - 15.4.1, supporting iPhone XS and newer.")
                            .multilineTextAlignment(.center)
                            .frame(width: descriptionMaxWidth)
                    }
                    .onPreferenceChange(DescriptionWidthPreferenceKey.self) {
                        descriptionMaxWidth = $0
                    }
                }.padding(.bottom)
                
                //
                // You should change the links below if you make any changes to Fugu15
                // so that others know where to find the source code
                //
                Link("Source Code", destination: URL(string: "https://github.com/ghh-jb/Fugu15_Rootful")!)
                    .padding([.top, .leading, .trailing])
                Link("License", destination: URL(string: "https://github.com/ghh-jb/Fugu15_Rootful/blob/master/LICENSE")!)
                    .padding([.top, .leading, .trailing])
                Link("Credits", destination: URL(string: "https://github.com/ghh-jb/Fugu15_Rootful/blob/master/README.md#Credits")!)
                    .padding([.top, .leading, .trailing])
                
                Spacer()
                
                Group {
                    Image("PinautenLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.leading, 100)
                        .padding(.trailing, 100)
                        .padding(.bottom)
                        .frame(maxHeight: 100)
                        .onTapGesture {
                            openURL(URL(string: "https://pinauten.de/")!)
                        }
                }.padding(.bottom, 25)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
