//
//  ContentView.swift
//  CMSAuditor
//
//  Created by Leo Watson on 30/03/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    // State for the current audit
    @State private var auditName: String = ""
    @State private var keyword: String = ""
    @State private var urlList: String = ""
    @State private var isRunning: Bool = false
    @State private var statusMessage: String = "Ready"
    
    // Holds results for the current session only
    @State private var currentResultsCSV: String?
    @State private var isShowingExporter = false
    @State private var documentToExport: CSVDocument?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    headerSection
                    
                    setupSection
                    
                    if let csv = currentResultsCSV {
                        resultsSection(csv: csv)
                    }
                }
                .padding(30)
            }
            .navigationTitle("Keyword Auditor")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if currentResultsCSV != nil {
                        Button(action: resetAudit) {
                            Label("Clear", systemImage: "arrow.counterclockwise")
                        }
                    }
                }
            }
            .fileExporter(
                isPresented: $isShowingExporter,
                document: documentToExport,
                contentType: .commaSeparatedText,
                defaultFilename: "\(auditName.isEmpty ? "audit_results" : auditName).csv"
            ) { _ in }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Native CMS Content Auditor")
                .font(.title2).bold()
            Text("Enter your URLs and keyword to generate a highlighted SEO report.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var setupSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Audit Name").font(.caption).bold()
                TextField("e.g. Weekly Compliance Check", text: $auditName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Keyword").font(.caption).bold()
                TextField("Keyword to find", text: $keyword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("URLs (one per line)").font(.caption).bold()
                TextEditor(text: $urlList)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
            }
            
            Button(action: startAudit) {
                if isRunning {
                    ProgressView().controlSize(.small).padding(.trailing, 5)
                }
                Text(isRunning ? "Auditing..." : "Run Audit & Generate Report")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning || keyword.isEmpty || urlList.isEmpty)
            
            Text("Status: \(statusMessage)")
                .font(.caption)
                .foregroundStyle(statusMessage.contains("Error") ? .red : .secondary)
        }
    }

    @ViewBuilder
    private func resultsSection(csv: String) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Divider()
            
            HStack {
                Text("Results").font(.headline)
                Spacer()
                Button {
                    documentToExport = CSVDocument(text: csv)
                    isShowingExporter = true
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            
            let entries = parseResults(csv)
            Table(entries) {
                TableColumn("URL") { Text($0.urlString).lineLimit(1) }
                TableColumn("Found") { entry in
                    let found = entry.found.lowercased() == "true"
                    Text(found ? "Yes" : "No")
                        .foregroundStyle(found ? .green : .secondary)
                        .bold(found)
                }
                TableColumn("Link") { entry in
                    if let url = entry.url {
                        Link("Open", destination: url).font(.caption)
                    }
                }
            }
            .frame(height: 300)
            .tableStyle(.bordered)
        }
    }

    private func startAudit() {
        isRunning = true
        currentResultsCSV = nil
        
        Task {
            let finalCSV = await performNativeAudit(keyword: keyword, urls: urlList) { progress in
                Task { @MainActor in self.statusMessage = progress }
            }
            
            await MainActor.run {
                self.currentResultsCSV = finalCSV
                self.isRunning = false
                self.statusMessage = "Audit Complete"
            }
        }
    }

    private func performNativeAudit(keyword: String, urls: String, progress: @escaping (String) -> Void) async -> String {
        let urlStrings = urls.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var results = ["URL,Keyword,Found,Count,Highlight_Link"]
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        
        for urlStr in urlStrings {
            progress("Scanning: \(urlStr)")
            guard let url = URL(string: urlStr), (url.scheme == "http" || url.scheme == "https") else {
                results.append("\(urlStr),\(keyword),Invalid URL,0,N/A")
                continue
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let html = String(data: data, encoding: .utf8) {
                    let occurrences = html.lowercased().components(separatedBy: keyword.lowercased()).count - 1
                    let found = occurrences > 0
                    let highlight = found ? "\(urlStr)#:~:text=\(encodedKeyword)" : "N/A"
                    results.append("\(urlStr),\(keyword),\(found),\(occurrences),\(highlight)")
                }
            } catch {
                results.append("\(urlStr),\(keyword),Network Error,0,N/A")
            }
        }
        return results.joined(separator: "\n")
    }

    private func parseResults(_ csv: String) -> [AuditEntry] {
        let lines = csv.components(separatedBy: .newlines)
        return lines.dropFirst().compactMap { line in
            let parts = line.components(separatedBy: ",")
            guard parts.count >= 5 else { return nil }
            return AuditEntry(urlString: parts[0], found: parts[2], highlightLink: parts[4])
        }
    }

    private func resetAudit() {
        currentResultsCSV = nil
        statusMessage = "Ready"
    }
}

private struct AuditEntry: Identifiable {
    let id = UUID()
    let urlString: String
    let found: String
    let highlightLink: String
    var url: URL? { URL(string: highlightLink != "N/A" ? highlightLink : urlString) }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.commaSeparatedText]
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws { text = "" }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: text.data(using: .utf8)!)
    }
}
