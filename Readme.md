# CMSAuditor

**CMSAuditor** is a lightweight, native macOS utility designed for SEO professionals and content managers to perform rapid keyword audits. By fetching live HTML content directly from a list of URLs, the app identifies keyword presence and generates an actionable report with "Scroll-to-Text" fragment links for instant verification.

---

## Features

* **Bulk URL Auditing:** Process multiple URLs simultaneously to check for specific keyword density.
* **Direct Text Highlighting:** Automatically generates `:~:text=` links for Google Chrome and Edge, navigating you directly to the found keyword on the page.
* **Live Status Tracking:** Real-time updates in the UI as the auditor scans through your list.
* **Native CSV Export:** Export your audit findings into a standard `.csv` file via the macOS file picker.
* **Modern SwiftUI Table:** View results instantly in a scannable, sortable table with status-aware color coding.

---

## Technical Stack

* **Language:** Swift 6.0
* **Framework:** SwiftUI
* **Concurrency:** Uses `async/await` and `Task` groups for non-blocking network requests.
* **File Handling:** Implements `FileDocument` for native system integration.

---

## Getting Started

### Prerequisites
* **macOS 14.0** or later.
* **Xcode 15.0** or higher.

### Installation
1. Clone the repository.
2. Open the project in Xcode.
3. Build and run (**Cmd + R**) on your Mac.

---

## How to Use

1. **Name the Audit:** Provide a reference name for the session, which is used as the default filename for export.
2. **Enter Keyword:** Specify the exact term you want to locate.
3. **Input URLs:** Paste your target URLs into the editor, one per line.
4. **Run Audit:** Click **Run Audit & Generate Report** to begin scanning.
5. **Review & Export:**
    * Check the **Results** table to see if the keyword was found.
    * Click **Open** to launch the URL in your browser with the keyword highlighted.
    * Click **Export CSV** to save the report to your local drive.

---

## Architecture

* **`CMSAuditorApp.swift`**: The main entry point of the application.
* **`ContentView.swift`**: Contains the core logic for the auditing engine, network requests, and the SwiftUI user interface.
* **`AuditEntry`**: A lightweight internal structure for managing table data and link generation.
* **`CSVDocument`**: A helper struct that enables native macOS file saving via `UniformTypeIdentifiers`.

---

**Author:** Leo Watson  
**Created:** March/April 2026