import SwiftUI

struct ContentView: View {
    let sampleTopic = Topic(
        title: "Biology: Cell Structure",
        materials: [
            StudyMaterial(title: "Cell Overview PDF", type: .pdf(name: "cell_overview")),
            StudyMaterial(title: "Cell Video", type: .video(url: URL(string: "https://www.youtube.com/watch?v=NwiK5X_lG5M&ab_channel=borko")!))
        ]
    )

    var body: some View {
        NavigationView {
            TopicDetailView(topic: sampleTopic)
        }
    }
}