//
//  ContentView.swift
//  TestKeychain
//
//  Created by Chip on 11/2/21.
//

import SwiftUI
import Security

struct ContentView: View {
    @State private var password = ""
    @State private var alertShown = false
    @State private var alertMessage = ""
    @State private var useDataProtection = true
    @State private var requireUserPresence = false
    @State private var applicationPassword = false
    
    let username = "foo"
    
    var body: some View {
        VStack {
            VStack {
                Toggle(isOn: $useDataProtection) {
                    Text("Data Protection Keychain")
                }
                Toggle(isOn: $requireUserPresence) {
                    Text("Require User Presence")
                }.disabled(!useDataProtection)
                Toggle(isOn: $applicationPassword) {
                    Text("Application Password")
                }.disabled(!useDataProtection)
            }
            HStack {
                Button(action: setKey) {
                    Text("Set Key")
                }
                Button(action: fetchKey) {
                    Text("Fetch Key")
                }
                Button(action: deleteKey) {
                    Text("Delete Key")
                }
            }
            TextField("Password", text: $password)
        }
        .frame(width:300)
        .padding(16)
        .alert(isPresented: $alertShown) {
            Alert(title: Text("Error"), message: Text(alertMessage))
        }
    }
    
    func showError(message: String) {
        alertMessage = message
        alertShown = true
    }
    
    func setKey() {
        let pwdata = password.data(using: String.Encoding.utf8)!
        
        var error: Unmanaged<CFError>?
        var accessFlags: SecAccessControlCreateFlags = []
        if requireUserPresence {
            accessFlags.insert(.userPresence)
        }
        if applicationPassword {
            accessFlags.insert(.applicationPassword)
        }
        let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlocked, accessFlags, &error)
        if error != nil {
            showError(message: "Error creating access control: \(String(describing: error))")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "Foo",
            kSecAttrAccount as String: username,
            kSecValueData as String: pwdata,
            kSecUseDataProtectionKeychain as String: useDataProtection,
            //kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccessControl as String: access!,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            let explanation = SecCopyErrorMessageString(status, nil)!
            showError(message: "Failed to store keychain item:" + (explanation as String))
            return
        }
    }
    
    func fetchKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
        ]

        var item: CFTypeRef? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            let explanation = SecCopyErrorMessageString(status, nil)!
            showError(message: "Could not find item:" + (explanation as String))
            return
        }

        guard let pwdata = item as? Data,
              let pw = String(data: pwdata, encoding: String.Encoding.utf8)
        else {
            showError(message: "Could not convert result")
            return
        }
        
        self.password = pw
    }
    
    func deleteKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            let explanation = SecCopyErrorMessageString(status, nil)!
            showError(message: "Could not find item:" + (explanation as String))
            return
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
