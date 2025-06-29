import SwiftUI

struct TopicDetailView: View {
    let topic: Topic
    @StateObject var progressManager = ProgressManager()
    @State private var selectedMaterial: StudyMaterial?
    @State private var showPDF = false
    @State private var showVideo = false

    var body: some View {
        VStack {
            Text(topic.title)
                .font(.largeTitle)
                .padding()

            List(topic.materials) { material in
                Button(action: {
                    selectedMaterial = material
                    switch material.type {
                    case .pdf: showPDF = true
                    case .video: showVideo = true
                    }
                    progressManager.lastMaterialID = material.id
                }) {
                    HStack {
                        Text(material.title)
                        Spacer()
                        if progressManager.lastMaterialID == material.id {
                            Text("Last viewed")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPDF) {
            if let material = selectedMaterial, case let .pdf(name) = material.type {
                PDFViewerView(
                    pdfName: name,
                    progressManager: progressManager,
                    materialID: material.id
                )
            }
        }
        .sheet(isPresented: $showVideo) {
            if let material = selectedMaterial, case let .video(url) = material.type {
                VideoViewerView(
                    videoURL: url,
                    progressManager: progressManager,
                    materialID: material.id
                )
            }
        }
        .onAppear {
            progressManager.loadProgress()
        }
    }
}