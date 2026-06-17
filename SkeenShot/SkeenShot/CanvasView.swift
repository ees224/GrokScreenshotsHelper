import SwiftUI
import UniformTypeIdentifiers

struct CanvasView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SkeenShot")
                .font(.title2.bold())

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                                  style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))

                if let image = appState.previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("Drop image here or press ⌘V")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(minHeight: 260)
            .onDrop(of: [UTType.image, UTType.png, UTType.tiff], isTargeted: $isTargeted) { providers in
                loadImage(from: providers)
            }

            TextField("Optional note for Grok", text: $appState.note)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Paste") { pasteFromClipboard() }
                Button("Clear") {
                    appState.previewImage = nil
                    appState.note = ""
                    appState.statusMessage = "Cleared."
                }
                Spacer()
                Button("Submit") { submit() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.previewImage == nil)
            }

            Text(appState.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 420)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command),
                   event.charactersIgnoringModifiers?.lowercased() == "v" {
                    pasteFromClipboard()
                    return nil
                }
                return event
            }
        }
    }

    private func pasteFromClipboard() {
        if let image = SkeenShotSaver.imageFromPasteboard(.general) {
            appState.previewImage = image
            appState.statusMessage = "Pasted from clipboard."
        } else {
            appState.statusMessage = "No image on clipboard."
        }
    }

    private func loadImage(from providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.canLoadObject(ofClass: NSImage.self) }) else {
            return false
        }
        _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
            DispatchQueue.main.async {
                if let img = image as? NSImage {
                    appState.previewImage = img
                    appState.statusMessage = "Image loaded."
                }
            }
        }
        return true
    }

    private func submit() {
        guard let image = appState.previewImage else { return }
        let note = appState.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let result = SkeenShotSaver.save(
            image: image,
            source: "canvas",
            note: note.isEmpty ? nil : note
        ) {
            appState.statusMessage = "Saved: \((result.imagePath as NSString).lastPathComponent)"
            appState.previewImage = nil
            appState.note = ""
        } else {
            appState.statusMessage = "Failed to save screenshot."
        }
    }
}