import SwiftUI

struct LabelCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void

    // MARK: – Selections & Pickers

    // 1) Tote Number: none + 1…8
    let toteOptions = ["None", "1", "2", "3", "4", "5", "6", "7", "8"]
    @State private var toteNumberSelection = "None"

    // 2) Small Order Number (E8850) – relabeled as Tote ID
    @State private var smallOrder      = "E8850"

    // 3) Due Time: use a DatePicker (hour & minute)
    @State private var dueTime: Date   = Date()

    // 4) Order Type: dropdown
    let orderTypes = ["UNSCHEDULED", "GMD", "Scheduled Pickup", "Delivery"]
    @State private var orderType       = "UNSCHEDULED"

    // 5) Customer Name (K. RODFGS)
    @State private var customerName    = "K. RODFGS"

    // 6) Full Order Number
    @State private var fullOrderNumber = "207532586748850"

    // 7) Tote ID (barcode J63063) – relabeled Tote Number
    @State private var toteID          = "J63063"

    // 8) Temperature Band: dropdown
    let tempBands = ["AMBIENT", "UNKNOWN", "FROZEN", "CHILLED"]
    @State private var temperatureBand = "AMBIENT"

    // MARK: – Flags
    @State private var isWalmartPlus   = true
    @State private var isAlcohol       = true
    @State private var isSubstitution  = true
    @State private var isFragile       = true
    @State private var isHeavy         = true
    @State private var isBagged        = true

    var body: some View {
        NavigationView {
            Form {
                // Tote number picker
                Section("Tote Number") {
                    Picker("Tote Number", selection: $toteNumberSelection) {
                        ForEach(toteOptions, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }

                // Order details
                Section("Order Details") {
                    TextField("Tote ID", text: $smallOrder)

                    DatePicker(
                        "Due Time",
                        selection: $dueTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)

                    Picker("Order Type", selection: $orderType) {
                        ForEach(orderTypes, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)

                    TextField("Name", text: $customerName)

                    TextField("Order Number", text: $fullOrderNumber)

                    TextField("Tote Number", text: $toteID)

                    Picker("Temperature Band", selection: $temperatureBand) {
                        ForEach(tempBands, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }

                // Flags
                Section("Flags") {
                    Toggle("Walmart Plus (W+)", isOn: $isWalmartPlus)
                    Toggle("Alcohol (A)",         isOn: $isAlcohol)
                    Toggle("Substitution (S)",    isOn: $isSubstitution)
                    Toggle("Fragile (F)",         isOn: $isFragile)
                    Toggle("Heavy (H)",           isOn: $isHeavy)
                    Toggle("Bagged (B)",          isOn: $isBagged)
                }
            }
            .navigationTitle("Customize Label")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(generateZPL())
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateZPL() -> String {
        var lines: [String] = ["^XA"]

        // Top-left circle + tote number
        if let num = Int(toteNumberSelection), (1...8).contains(num) {
            lines += [
                "^FO0,0^GC104,104,155,B^FS",
                "^CF0,86",
                "^FO32,22^FR^FD\(num)^FS"
            ]
        }

        // Flags (B, H, F, S, A) at fixed Y offsets
        let flagSpecs: [(Bool, String, Int)] = [
            (isBagged,      "B",  10),
            (isHeavy,       "H", 118),
            (isFragile,     "F", 226),
            (isSubstitution,"S", 334),
            (isAlcohol,     "A", 442)
        ]
        lines.append("^CF0,60")
        for (on, label, y) in flagSpecs where on {
            lines += [
                "^FO505,\(y)^GB100,100,2^FS",
                "^FO525,\(y+30)^FD\(label)^FS"
            ]
        }

        // Center column
        let dueFormatter = DateFormatter()
        dueFormatter.dateFormat = "h:mm a"
        let dueTimeStr = dueFormatter.string(from: dueTime)

        lines += [
            "^CF0,90",
            "^FO125,52^FB360,1,0,C,0^FD\(smallOrder)^FS",
            "^CF0,50",
            "^FO125,142^FB360,1,0,C,0^FD\(dueTimeStr)^FS",
            "^CF0,45",
            "^FO125,202^FB360,1,0,C,0^FD\(orderType)^FS",
            "^FO125,252^FB360,1,0,C,0^FD\(customerName)^FS",
            "^CF0,35",
            "^FO125,302^FB360,1,0,C,0^FD\(fullOrderNumber)^FS",
            "^BY3,3,100",
            "^FO145,352^BCN,100,N,N,N",
            "^FD\(toteID)^FS",
            "^CF0,40",
            "^FO125,462^FB360,1,0,C,0^FD\(temperatureBand)^FS"
        ]

        // Footer W+
        if isWalmartPlus {
            lines += [
                "^CF0,75",
                "^FO0,500^FDW+^FS"
            ]
        }

        // Print-date & print-time (fixed, non-editable)
        let now = Date()
        let df = DateFormatter()
        df.dateFormat = "dd-MMM"
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"

        lines += [
            "^CF0,30",
            "^FO0,579^FD\(df.string(from: now))^FS",
            "^FO125,579^FB360,1,0,C,0^FD\(tf.string(from: now))^FS",
            "^FO520,579^FD\(toteID)^FS",
            "^XZ"
        ]

        return lines.joined(separator: "\n")
    }
}
