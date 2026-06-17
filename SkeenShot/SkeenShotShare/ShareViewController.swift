import AppKit
import UniformTypeIdentifiers

class ShareViewController: NSViewController {
    private let noteField = NSTextField(string: "")
    private let statusLabel = NSTextField(labelWithString: "Send screenshot to Grok")
    private var loadedImage: NSImage?

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 140))

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        noteField.translatesAutoresizingMaskIntoConstraints = false
        noteField.placeholderString = "Optional note"

        let saveButton = NSButton(title: "Send to Grok", target: self, action: #selector(saveTapped))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        view.addSubview(statusLabel)
        view.addSubview(noteField)
        view.addSubview(saveButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            noteField.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            noteField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            noteField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            saveButton.topAnchor.constraint(equalTo: noteField.bottomAnchor, constant: 12),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])

        loadAttachments()
    }

    private func loadAttachments() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        for item in items {
            guard let providers = item.attachments else { continue }
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let image = item as? NSImage {
                                self?.loadedImage = image
                            } else if let url = item as? URL, let image = NSImage(contentsOf: url) {
                                self?.loadedImage = image
                            } else if let data = item as? Data, let image = NSImage(data: data) {
                                self?.loadedImage = image
                            }
                            self?.statusLabel.stringValue = self?.loadedImage == nil
                                ? "No image found"
                                : "Ready to send to Grok"
                        }
                    }
                    return
                }
            }
        }
    }

    @objc private func saveTapped() {
        guard let image = loadedImage else {
            extensionContext?.cancelRequest(withError: NSError(domain: "SkeenShot", code: 1))
            return
        }
        let note = noteField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if SkeenShotSaver.save(
            image: image,
            source: "share_extension",
            note: note.isEmpty ? nil : note
        ) != nil {
            extensionContext?.completeRequest(returningItems: nil)
        } else {
            extensionContext?.cancelRequest(withError: NSError(domain: "SkeenShot", code: 2))
        }
    }
}