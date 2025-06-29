import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let pdfName: String
    @ObservedObject var progressManager: ProgressManager
    let materialID: UUID
    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentPage = 0
    @State private var totalPages = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else if isLoading {
                    loadingView
                } else if let document = pdfDocument {
                    PDFKitView(
                        document: document,
                        progressManager: progressManager,
                        materialID: materialID,
                        currentPage: $currentPage,
                        totalPages: $totalPages
                    )
                }
            }
            .navigationTitle("PDF Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Progress is automatically saved by PDFKitView
                    }
                }
            }
        }
        .onAppear {
            loadPDF()
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading PDF...")
                .font(.headline)
                .padding(.top)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("PDF Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                loadPDF()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func loadPDF() {
        isLoading = true
        errorMessage = nil
        
        // Try to load PDF from bundle first
        if let url = Bundle.main.url(forResource: pdfName, withExtension: "pdf"),
           let document = PDFDocument(url: url) {
            self.pdfDocument = document
            self.totalPages = document.pageCount
            self.currentPage = 0
            isLoading = false
            return
        }
        
        // Try to load from documents directory (for downloaded PDFs)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let documentsPath = documentsPath {
            let pdfURL = documentsPath.appendingPathComponent("\(pdfName).pdf")
            if let document = PDFDocument(url: pdfURL) {
                self.pdfDocument = document
                self.totalPages = document.pageCount
                self.currentPage = 0
                isLoading = false
                return
            }
        }
        
        // If we get here, the PDF couldn't be loaded
        errorMessage = "Could not load PDF file: \(pdfName).pdf"
        isLoading = false
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @ObservedObject var progressManager: ProgressManager
    let materialID: UUID
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        
        // Set up delegate for page tracking
        pdfView.delegate = context.coordinator
        
        // Load saved progress
        if progressManager.lastMaterialID == materialID {
            let savedPage = progressManager.lastPDFPage
            if savedPage < document.pageCount {
                if let page = document.page(at: savedPage) {
                    pdfView.go(to: page)
                    currentPage = savedPage
                }
            }
        }
        
        totalPages = document.pageCount
        currentPage = 0
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update is handled by the delegate
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        let parent: PDFKitView
        
        init(_ parent: PDFKitView) {
            self.parent = parent
        }
        
        func pdfViewPageChanged(_ pdfView: PDFView) {
            if let currentPage = pdfView.currentPage,
               let pageIndex = pdfView.document?.index(for: currentPage) {
                parent.currentPage = pageIndex
                parent.progressManager.saveProgress(
                    materialID: parent.materialID,
                    pdfPage: pageIndex
                )
            }
        }
    }
}