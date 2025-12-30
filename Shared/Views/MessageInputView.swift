import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct MessageInputView: View {
    let onSend: (String?, Data?) -> Void

    @State private var text = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        !text.isEmpty || selectedImageData != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image preview (when selected)
            if let imageData = selectedImageData, let image = createImage(from: imageData) {
                HStack {
                    ZStack(alignment: .topTrailing) {
                        #if canImport(UIKit)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        #elseif canImport(AppKit)
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        #endif

                        // Remove button
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedItem = nil
                                selectedImageData = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white, .black.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 6, y: -6)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }

            HStack(spacing: 12) {
                // Photo picker button
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    Circle()
                                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                                }
                        }
                }
                .buttonStyle(.plain)

                // Glass text field
                HStack(spacing: 8) {
                    TextField("Message", text: $text)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit(sendMessage)
                        .submitLabel(.send)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    }
                }

                // Glass send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: canSend
                                            ? [Color.blue, Color.blue.opacity(0.8)]
                                            : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay {
                                    Circle()
                                        .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
                                }
                                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedImageData = compressImage(data)
                        }
                    }
                }
            }
        }
    }

    private func sendMessage() {
        guard canSend else { return }
        let messageText = text.isEmpty ? nil : text
        onSend(messageText, selectedImageData)
        text = ""
        selectedItem = nil
        selectedImageData = nil
    }

    private func createImage(from data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #endif
    }

    private func compressImage(_ data: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return data }

        // Resize if too large
        let maxDimension: CGFloat = 1024
        var targetSize = image.size
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        // Compress to JPEG with quality that keeps it under ~80KB
        var quality: CGFloat = 0.7
        var compressedData = resizedImage.jpegData(compressionQuality: quality)
        while let data = compressedData, data.count > 80_000, quality > 0.1 {
            quality -= 0.1
            compressedData = resizedImage.jpegData(compressionQuality: quality)
        }

        return compressedData
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else { return data }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return data }

        // Resize if too large
        let maxDimension: CGFloat = 1024
        var targetSize = image.size
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        }

        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: targetSize))
        resizedImage.unlockFocus()

        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return data }

        // Compress to JPEG
        var quality: CGFloat = 0.7
        var compressedData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        while let data = compressedData, data.count > 80_000, quality > 0.1 {
            quality -= 0.1
            compressedData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
        }

        return compressedData
        #endif
    }
}

#if canImport(UIKit)
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
private typealias PlatformImage = NSImage
#endif

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            MessageInputView(onSend: { _, _ in })
                .background(.ultraThinMaterial)
        }
    }
}
