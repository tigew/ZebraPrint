import SwiftUI

enum ConnectionType: String, CaseIterable, Identifiable {
    case bluetooth = "Bluetooth"
    case network   = "Network"
    
    var id: String { rawValue }
}

struct ContentView: View {
    @State private var connectionType     = ConnectionType.bluetooth
    @State private var endpoint: String   = ""
    @State private var zplCode: String    = ""
    @State private var logs: [String]     = ["Ready"]

    @State private var showConsole        = false
    @State private var showLabelEditor    = false
    @State private var showClearConfirm   = false

    var body: some View {
        VStack(spacing: 16) {
            // Connection picker
            Picker("Connection", selection: $connectionType) {
                ForEach(ConnectionType.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            // Endpoint field
            TextField(
                connectionType == .bluetooth
                    ? "Printer Serial Number"
                    : "Printer IP Address (e.g. 192.168.1.42)",
                text: $endpoint
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())

            // ZPL entry
            Text("ZPL Command:")
                .font(.headline)
            TextEditor(text: $zplCode)
                .border(Color.gray)
                .frame(minHeight: 200)

            // Buttons: Print / Console / Label / Clear
            HStack(spacing: 12) {
                Button("Print") {
                    sendZPL()
                }
                Button("Console") {
                    showConsole.toggle()
                }
                Button("Label") {
                    showLabelEditor.toggle()
                }
                Button("Clear") {
                    showClearConfirm = true
                }
                .tint(.red)
            }
            .buttonStyle(.borderedProminent)

            // Status line
            Text("Status: \(logs.last ?? "")")
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        // Console sheet
        .sheet(isPresented: $showConsole) {
            ConsoleView(logs: logs)
        }
        // Label editor sheet
        .sheet(isPresented: $showLabelEditor) {
            LabelCustomizationView { newZPL in
                zplCode = newZPL
            }
        }
        // Clear confirmation alert
        .alert("Clear ZPL?", isPresented: $showClearConfirm) {
            Button("Delete", role: .destructive) {
                zplCode = ""
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to clear the ZPL input?")
        }
    }

    // sendZPL() unchanged...
    func sendZPL() {
        logs.append("⏳ Starting print via \(connectionType.rawValue)...")

        let rawConn: AnyObject? = {
            switch connectionType {
            case .bluetooth:
                return MfiBtPrinterConnection(serialNumber: endpoint)
            case .network:
                return TcpPrinterConnection(
                    address: endpoint,
                    andWithPort: 9100
                )
            }
        }()
        guard let conn = rawConn as? ZebraPrinterConnection else {
            logs.append("❌ Invalid endpoint “\(endpoint)”")
            return
        }

        guard conn.open() else {
            logs.append("❌ Couldn’t open \(connectionType.rawValue) connection")
            return
        }
        defer {
            conn.close()
            logs.append("🔌 Connection closed")
        }

        let data = Data(zplCode.utf8)
        var error: NSError?
        let sent = conn.write(data, error: &error)

        if sent <= 0 {
            logs.append("❌ Send failed: \(error?.localizedDescription ?? "unknown")")
        } else {
            logs.append("✅ Sent \(sent)/\(data.count) bytes")
        }
    }
}

struct ConsoleView: View {
    let logs: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(logs.joined(separator: "\n"))
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Console")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
