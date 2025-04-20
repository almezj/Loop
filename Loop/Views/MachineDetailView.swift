import SwiftUI

struct MachineDetailView: View {
    let machine: MachineLocation
    let onReportUnavailable: () -> Void
    let onReportAvailable: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(machine.name)
                .font(.title)
            Text(machine.address)
                .font(.subheadline)
            
            if machine.currentStatus == .reportedUnavailable {
                Text("Reported Unavailable")
                    .foregroundColor(.orange)
            }
            
            // Report History
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Reports")
                    .font(.headline)
                
                if machine.reports.isEmpty {
                    Text("No reports yet")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                } else {
                    ForEach(machine.reports.sorted(by: { $0.timestamp > $1.timestamp }).prefix(5)) { report in
                        HStack {
                            Image(systemName: report.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(report.isAvailable ? .green : .orange)
                            Text(report.isAvailable ? "Reported Available" : "Reported Unavailable")
                            Spacer()
                            Text(report.timestamp, style: .relative)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            
            // Buttons - Need better styling (placing them statically at the bottom or something like that)
            HStack(spacing: 20) {
                Button(action: onReportUnavailable) {
                    Text("Report Unavailable")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(10)
                }
                
                Button(action: onReportAvailable) {
                    Text("Report Available")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
} 