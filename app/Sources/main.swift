import SwiftUI
import ImagePlayground
import AppKit

@main
struct ImageHelperApp: App {
    @State private var hasStarted = false

    init() {
        // Force to foreground — ImageCreator requires foreground app
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if !hasStarted {
                        hasStarted = true
                        runGeneration()
                    }
                }
        }
    }

    func runGeneration() {
        Task { @MainActor in
            // Give the app time to fully activate and become the key window
            // The foreground check happens at generation time, not init time
            try? await Task.sleep(for: .seconds(2))

            // Force activation again after window is visible
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
            try? await Task.sleep(for: .milliseconds(500))

            // Read parameters from environment variables
            // (When launched via `open`, ProcessInfo.arguments only has the bundle path)
            let env = ProcessInfo.processInfo.environment

            // Also support CLI args for direct invocation
            let args = ProcessInfo.processInfo.arguments
            var cliPrompt: String?
            var cliStyleStr: String?
            var cliOutputPath: String?

            var i = 1
            while i < args.count {
                switch args[i] {
                case "--prompt":
                    if i + 1 < args.count { cliPrompt = args[i + 1]; i += 1 }
                case "--style":
                    if i + 1 < args.count { cliStyleStr = args[i + 1]; i += 1 }
                case "--output":
                    if i + 1 < args.count { cliOutputPath = args[i + 1]; i += 1 }
                default:
                    break
                }
                i += 1
            }

            // CLI args override env vars
            let prompt = cliPrompt ?? env["IMAGE_HELPER_PROMPT"]
            let styleStr = (cliStyleStr ?? env["IMAGE_HELPER_STYLE"])?.lowercased() ?? "illustration"
            let outputPath = cliOutputPath ?? env["IMAGE_HELPER_OUTPUT"]

            guard let prompt = prompt, !prompt.isEmpty, let outputPath = outputPath, !outputPath.isEmpty else {
                print("Usage: image-helper --prompt \"text\" --style illustration|animation|sketch --output /path/to/save.png")
                print("  Or set env vars: IMAGE_HELPER_PROMPT, IMAGE_HELPER_STYLE, IMAGE_HELPER_OUTPUT")
                NSApplication.shared.terminate(nil)
                return
            }

            // Map style string to ImagePlaygroundStyle
            let style: ImagePlaygroundStyle
            switch styleStr {
            case "animation":
                style = .animation
            case "sketch":
                style = .sketch
            default:
                style = .illustration
            }

            // Build concepts array
            let concepts: [ImagePlaygroundConcept] = [.text(prompt)]

            print("image-helper: Generating image for prompt: \"\(prompt)\" with style: \(styleStr)")

            do {
                // ImageCreator.init() is async throws
                let creator = try await ImageCreator()
                print("image-helper: ImageCreator initialized, starting generation...")

                let sequence = creator.images(for: concepts, style: style, limit: 1)

                var imageFound = false
                for try await createdImage in sequence {
                    let cgImg = createdImage.cgImage
                    print("image-helper: Image received! Size: \(cgImg.width)x\(cgImg.height)")

                    let nsImage = NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))

                    if saveImage(nsImage, to: outputPath) {
                        print("image-helper: Successfully saved to \(outputPath)")
                        imageFound = true
                    } else {
                        print("image-helper: ERROR - Failed to save image to \(outputPath)")
                    }
                    break
                }

                if !imageFound {
                    print("image-helper: ERROR - No image was generated (empty sequence)")
                }
            } catch {
                let errorStr = String(describing: error)
                print("image-helper: Generation failed: \(error)")

                if errorStr.contains("backgroundCreationForbidden") {
                    print("image-helper: CRITICAL - backgroundCreationForbidden even with activate(). The foreground requirement blocks this approach.")
                }
            }

            // Auto-exit after completion
            NSApplication.shared.terminate(nil)
        }
    }

    func saveImage(_ image: NSImage, to path: String) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        let url = URL(fileURLWithPath: path)
        do {
            // Ensure parent directory exists
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try pngData.write(to: url)
            return true
        } catch {
            print("image-helper: Write error: \(error)")
            return false
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.purple)
            Text("Image Playground Helper")
                .font(.headline)
            Text("Generating image...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView()
        }
        .frame(width: 300, height: 200)
    }
}
