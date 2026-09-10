import SwiftUI

struct PipelineMonitorView: View {
    @State private var viewModel = PipelineMonitorViewModel()
    @State private var autoRefresh = true

    var body: some View {
        List {
            healthSection
            progressSection
            trackedMediaSection
            recentJobsSection
            if !viewModel.failedJobsList.isEmpty {
                failedJobsSection
            }
            triggerSection
        }
        .navigationTitle("Pipeline Monitor")
        .task {
            await viewModel.loadAll()
        }
        .refreshable {
            await viewModel.loadAll()
        }
        .task(id: autoRefresh) {
            guard autoRefresh else { return }
            while !Task.isCancelled && autoRefresh {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { break }
                await viewModel.loadAll()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    autoRefresh.toggle()
                } label: {
                    Image(systemName: autoRefresh ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                }
            }
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        Section {
            HStack {
                Label("Scheduler", systemImage: "clock.arrow.circlepath")
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.schedulerRunning ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.schedulerRunning ? "Running" : "Stopped")
                        .foregroundStyle(viewModel.schedulerRunning ? .green : .red)
                        .font(.subheadline.weight(.medium))
                }
            }

            HStack {
                Label("Tracked Media", systemImage: "tv")
                Spacer()
                Text("\(viewModel.trackedMediaCount)")
                    .foregroundStyle(.secondary)
                    .font(.subheadline.weight(.medium))
            }

            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Server Status")
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 12)

                        if viewModel.totalJobs > 0 {
                            let completedWidth = geometry.size.width * CGFloat(viewModel.completedJobs) / CGFloat(viewModel.totalJobs)
                            let failedWidth = geometry.size.width * CGFloat(viewModel.failedJobs) / CGFloat(viewModel.totalJobs)

                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.green)
                                    .frame(width: max(completedWidth, 0), height: 12)

                                if viewModel.failedJobs > 0 {
                                    Rectangle()
                                        .fill(.red)
                                        .frame(width: max(failedWidth, 0), height: 12)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .frame(height: 12)

                // Stats row
                HStack {
                    jobStatLabel(count: viewModel.completedJobs, label: "Completed", color: .green)
                    Spacer()
                    jobStatLabel(count: viewModel.pendingJobs, label: "Pending", color: .orange)
                    Spacer()
                    jobStatLabel(count: viewModel.failedJobs, label: "Failed", color: .red)
                }
            }
            .padding(.vertical, 4)

            if viewModel.totalJobs > 0 {
                HStack {
                    Text("Overall Progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%%", viewModel.completionPercentage))
                        .font(.subheadline.weight(.semibold))
                }
            }
        } header: {
            Text("Job Progress")
        }
    }

    private func jobStatLabel(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tracked Media Section

    private var trackedMediaSection: some View {
        Section {
            if viewModel.trackedMedia.isEmpty {
                ContentUnavailableView("No Tracked Media", systemImage: "tv.slash",
                                       description: Text("Run discovery to find anime and dramas."))
            } else {
                ForEach(viewModel.trackedMedia, id: \.id) { media in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(media.title)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)
                            HStack(spacing: 8) {
                                Text(media.mediaType.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())

                                if let status = media.status {
                                    Text(status.capitalized)
                                        .font(.caption2)
                                        .foregroundStyle(statusColor(status))
                                }

                                if let total = media.totalEpisodes {
                                    Text("\(media.airedEpisodes)/\(total) eps")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                    }
                }
            }
        } header: {
            HStack {
                Text("Tracked Media")
                Spacer()
                Text("\(viewModel.trackedMedia.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "airing": return .green
        case "finished": return .secondary
        case "upcoming": return .orange
        default: return .secondary
        }
    }

    // MARK: - Recent Jobs Section

    private var recentJobsSection: some View {
        Section {
            if viewModel.recentJobs.isEmpty {
                Text("No completed jobs yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentJobs, id: \.id) { job in
                    jobRow(job)
                }
            }
        } header: {
            Text("Recently Completed")
        }
    }

    // MARK: - Failed Jobs Section

    private var failedJobsSection: some View {
        Section {
            ForEach(viewModel.failedJobsList, id: \.id) { job in
                VStack(alignment: .leading, spacing: 4) {
                    jobRow(job)
                    if let error = job.lastError {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }
            }
        } header: {
            HStack {
                Text("Failed Jobs")
                Spacer()
                Text("\(viewModel.failedJobsList.count)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func jobRow(_ job: AnimangoAPIService.ContentJobDTO) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.mediaTitle(for: job.mediaId))
                    .font(.subheadline)
                    .lineLimit(1)
                Text("Episode \(job.episodeNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                jobStatusBadge(job.status)
                if let source = job.source {
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func jobStatusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(jobStatusColor(status).opacity(0.15))
            .foregroundStyle(jobStatusColor(status))
            .clipShape(Capsule())
    }

    private func jobStatusColor(_ status: String) -> Color {
        switch status {
        case "completed": return .green
        case "pending": return .orange
        case "downloading", "processing": return .blue
        case "failed": return .red
        case "skipped": return .secondary
        default: return .secondary
        }
    }

    // MARK: - Trigger Section

    private var triggerSection: some View {
        Section {
            Button {
                Task { await viewModel.triggerDiscovery() }
            } label: {
                Label("Run Discovery", systemImage: "magnifyingglass")
            }
            .disabled(viewModel.isTriggering)

            Button {
                Task { await viewModel.triggerMonitor() }
            } label: {
                Label("Check for New Episodes", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(viewModel.isTriggering)

            Button {
                Task { await viewModel.triggerProcess() }
            } label: {
                Label("Process Next Job", systemImage: "play.circle")
            }
            .disabled(viewModel.isTriggering)

            if viewModel.isTriggering {
                HStack {
                    ProgressView()
                    Text("Running...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let message = viewModel.triggerMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Manual Triggers")
        } footer: {
            Text("These actions are also run automatically by the scheduler.")
        }
    }
}

#Preview {
    NavigationStack {
        PipelineMonitorView()
    }
}
