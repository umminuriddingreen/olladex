import SwiftUI

struct ContentView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        ZStack {
            Palette.canvas.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 22) {
                        routeLine
                        HStack(alignment: .top, spacing: 18) {
                            modelsPanel
                            diagnosticsPanel
                                .frame(width: 260)
                        }
                        if let message = store.message { status(message) }
                    }
                    .padding(28)
                }
            }
        }
        .confirmationDialog(
            "Route new Codex tasks through \(store.selectedModel)?",
            isPresented: $store.showingActivationConfirmation,
            titleVisibility: .visible
        ) {
            Button("Activate local model") { Task { await store.confirmActivation() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Olladex will back up ~/.codex/config.toml before changing its provider and model keys.")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("OLLADEx")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .tracking(2.4)
            Text("LOCAL ROUTE CONTROL")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.muted)
                .tracking(1.2)
            Spacer()
            Button { Task { await store.refresh() } } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(store.isWorking)
            .accessibilityLabel("Refresh status")
        }
        .padding(.horizontal, 28)
        .frame(height: 58)
        .background(Palette.panel)
        .overlay(alignment: .bottom) { Rectangle().fill(Palette.rule).frame(height: 1) }
    }

    private var routeLine: some View {
        HStack(spacing: 12) {
            routeNode("CODEX", systemImage: "chevron.left.forwardslash.chevron.right")
            connector(active: true)
            routeNode(store.route.providerName.uppercased(), systemImage: store.route.providerName == "Ollama" ? "lock.laptopcomputer" : "cloud")
            connector(active: store.route.providerName == "Ollama")
            VStack(alignment: .leading, spacing: 3) {
                Text("ACTIVE MODEL")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Palette.muted)
                Text(store.route.modelName)
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .lineLimit(1)
            }
            Spacer()
            Circle()
                .fill(store.ollamaVersion == nil ? Palette.warning : Palette.ready)
                .frame(width: 8, height: 8)
            Text(store.ollamaVersion.map { "OLLAMA \($0)" } ?? "OLLAMA OFFLINE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.muted)
        }
        .padding(20)
        .background(Palette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(Palette.rule) }
    }

    private var modelsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Installed models", detail: "\(store.models.count) found")
            if store.models.isEmpty {
                ContentUnavailableView("No models available", systemImage: "shippingbox", description: Text("Open Ollama, pull a tool-capable model, then refresh."))
                    .frame(maxWidth: .infinity, minHeight: 230)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.models) { model in
                        modelRow(model)
                    }
                }
            }
            HStack {
                Button("Activate local model") { store.activateSelectedModel() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(store.selectedModel.isEmpty || store.isWorking)
                Button("Open Codex") { store.openCodex() }
                    .buttonStyle(SecondaryButtonStyle())
            }
        }
        .panelStyle()
    }

    private var diagnosticsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Readiness", detail: nil)
            diagnostic("Ollama server", ok: store.ollamaVersion != nil)
            diagnostic("Installed model", ok: !store.models.isEmpty)
            diagnostic("Codex config", ok: store.route != .unknown)
            Divider().overlay(Palette.rule)
            Text("Switching changes only the top-level provider and model. Every activation creates a timestamped backup first.")
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Restore previous config") { Task { await store.restoreOpenAI() } }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(store.isWorking)
        }
        .panelStyle()
    }

    private func modelRow(_ model: OllamaModel) -> some View {
        Button {
            store.selectedModel = model.name
        } label: {
            HStack(spacing: 12) {
                Image(systemName: store.selectedModel == model.name ? "record.circle.fill" : "circle")
                    .foregroundStyle(store.selectedModel == model.name ? Palette.accent : Palette.muted)
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.name).font(.system(size: 14, weight: .semibold, design: .monospaced))
                    Text(model.formattedSize).font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.muted)
                }
                Spacer()
                if store.route.modelName == model.name && store.route.providerName == "Ollama" {
                    Text("ACTIVE").tagStyle(color: Palette.ready)
                }
            }
            .padding(12)
            .background(store.selectedModel == model.name ? Palette.selection : Palette.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).stroke(store.selectedModel == model.name ? Palette.accent.opacity(0.7) : Palette.rule) }
        }
        .buttonStyle(.plain)
    }

    private func routeNode(_ label: String, systemImage: String) -> some View {
        Label(label, systemImage: systemImage)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 11).padding(.vertical, 8)
            .background(Palette.canvas)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(Palette.rule) }
    }

    private func connector(active: Bool) -> some View {
        HStack(spacing: 2) {
            Rectangle().frame(width: 16, height: 1)
            Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(active ? Palette.accent : Palette.muted)
    }

    private func sectionTitle(_ title: String, detail: String?) -> some View {
        HStack {
            Text(title).font(.system(size: 17, weight: .bold))
            Spacer()
            if let detail { Text(detail).font(.system(size: 11, design: .monospaced)).foregroundStyle(Palette.muted) }
        }
    }

    private func diagnostic(_ label: String, ok: Bool) -> some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? Palette.ready : Palette.warning)
            Text(label).font(.system(size: 13, weight: .medium))
            Spacer()
            Text(ok ? "READY" : "CHECK").tagStyle(color: ok ? Palette.ready : Palette.warning)
        }
    }

    private func status(_ status: StatusMessage) -> some View {
        HStack {
            Image(systemName: status.kind == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            Text(status.text).font(.system(size: 12, design: .monospaced))
            Spacer()
        }
        .foregroundStyle(status.kind == .success ? Palette.ready : Palette.warning)
        .padding(14)
        .background(Palette.panel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private enum Palette {
    static let canvas = Color(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(hex: 0x10151B) : NSColor(hex: 0xEEF3F6) })
    static let panel = Color(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(hex: 0x171E26) : NSColor(hex: 0xF8FAFB) })
    static let rule = Color(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(hex: 0x2B3743) : NSColor(hex: 0xCBD5DC) })
    static let muted = Color(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(hex: 0x92A1AE) : NSColor(hex: 0x60717E) })
    static let accent = Color(nsColor: NSColor(hex: 0x52A9FF))
    static let selection = accent.opacity(0.10)
    static let ready = Color(nsColor: NSColor(hex: 0x4BC38A))
    static let warning = Color(nsColor: NSColor(hex: 0xE8A84B))
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: 1)
    }
}

private extension View {
    func panelStyle() -> some View {
        self.padding(20).background(Palette.panel).clipShape(RoundedRectangle(cornerRadius: 14)).overlay { RoundedRectangle(cornerRadius: 14).stroke(Palette.rule) }
    }

    func tagStyle(color: Color) -> some View {
        self.font(.system(size: 9, weight: .black, design: .monospaced)).foregroundStyle(color).padding(.horizontal, 7).padding(.vertical, 4).background(color.opacity(0.12)).clipShape(Capsule())
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 16).padding(.vertical, 10).background(Palette.accent.opacity(configuration.isPressed ? 0.72 : 1)).clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 9).background(Palette.canvas.opacity(configuration.isPressed ? 0.6 : 1)).clipShape(RoundedRectangle(cornerRadius: 9)).overlay { RoundedRectangle(cornerRadius: 9).stroke(Palette.rule) }
    }
}
