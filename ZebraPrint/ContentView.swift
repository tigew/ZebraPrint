import SwiftUI

struct ContentView: View {
    @State private var zplCode    = ""
    @State private var macAddress = ""
    @State private var status     = "Ready"

    var body: some View {
        VStack(spacing: 16) {
            Text("ZPL Command:")
                .font(.headline)
            TextEditor(text: $zplCode)
                .border(Color.gray)
                .frame(minHeight: 200)

            TextField("Printer MAC/Serial", text: $macAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Print") {
                sendZPL()
            }
            .padding(.vertical)
            .buttonStyle(.borderedProminent)

            Text(status)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }

    func sendZPL() {
        // Attempt to create and unwrap the Bluetooth connection
        guard let connection = MfiBtPrinterConnection(serialNumber: macAddress) else {
            status = "❌ Invalid MAC/Serial"
            return
        }

        // Open the connection
        guard connection.open() else {
            status = "❌ Couldn’t open connection"
            return
        }
        defer { connection.close() }

        // Send the ZPL data
        let data = Data(zplCode.utf8)
        var error: NSError?
        let bytesSent = connection.write(data, error: &error)

        if bytesSent == -1 {
            status = "❌ Error: \(error?.localizedDescription ?? "unknown")"
        } else {
            status = "✅ Sent \(bytesSent) bytes"
        }
    }
}
