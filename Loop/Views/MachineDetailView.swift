import SwiftUI
import CoreLocation

struct MachineDetailView: View {
    let machine: MachineLocation
    let onReportUnavailable: () -> Void
    let onReportAvailable: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with status
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Image(systemName: machine.currentStatus == .available ? "checkmark.circle.fill" : 
                              machine.currentStatus == .reportedUnavailable ? "xmark.circle.fill" : "questionmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(machine.currentStatus.color)
                        
                        Text(machine.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.brandGreen)
                    }
                    
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color.brandGreen.opacity(0.7))
                        Text(machine.address)
                            .font(.subheadline)
                            .foregroundColor(Color.brandGreen.opacity(0.7))
                    }
                }
                
                // Recent Reports Timeline
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color.brandGreen)
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundColor(Color.brandGreen)
                    }
                    
                    if machine.reports.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(Color.brandGreen.opacity(0.7))
                            Text("No reports yet")
                                .foregroundColor(Color.brandGreen.opacity(0.7))
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.brandGreen.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(machine.reports.sorted(by: { $0.timestamp > $1.timestamp }).prefix(3)) { report in
                                HStack(spacing: 12) {
                                    Image(systemName: report.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(report.isAvailable ? .green : .orange)
                                    
                                    Text(report.timestamp, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(Color.brandGreen.opacity(0.7))
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.brandGreen.opacity(0.1))
                                
                                if report != machine.reports.sorted(by: { $0.timestamp > $1.timestamp }).prefix(3).last {
                                    Divider()
                                        .background(Color.brandGreen.opacity(0.2))
                                }
                            }
                        }
                        .cornerRadius(10)
                    }
                }
                
                // Report Actions
                VStack(spacing: 12) {
                    Button(action: onReportUnavailable) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Report Unavailable")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    
                    Button(action: onReportAvailable) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Report Available")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 32)
        }
    }
} 