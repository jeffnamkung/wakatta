import Foundation

@Observable
class PipelineMonitorViewModel {
    private let api = AnimangoAPIService()

    // Health
    var schedulerRunning = false
    var trackedMediaCount = 0
    var pendingJobs = 0
    var completedJobs = 0
    var failedJobs = 0

    // Tracked media
    var trackedMedia: [AnimangoAPIService.TrackedMediaDTO] = []

    // Recent jobs
    var recentJobs: [AnimangoAPIService.ContentJobDTO] = []
    var failedJobsList: [AnimangoAPIService.ContentJobDTO] = []

    // State
    var isLoading = false
    var errorMessage: String?
    var triggerMessage: String?
    var isTriggering = false

    var totalJobs: Int {
        pendingJobs + completedJobs + failedJobs
    }

    var completionPercentage: Double {
        guard totalJobs > 0 else { return 0 }
        return Double(completedJobs) / Double(totalJobs) * 100
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadHealth() }
            group.addTask { await self.loadTrackedMedia() }
            group.addTask { await self.loadRecentJobs() }
            group.addTask { await self.loadFailedJobs() }
        }

        isLoading = false
    }

    private func loadHealth() async {
        do {
            let health = try await api.fetchPipelineHealth()
            await MainActor.run {
                schedulerRunning = health.schedulerRunning
                trackedMediaCount = health.trackedMediaCount
                pendingJobs = health.pendingJobs
                completedJobs = health.completedJobs
                failedJobs = health.failedJobs
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load health: \(error.localizedDescription)"
            }
        }
    }

    private func loadTrackedMedia() async {
        do {
            let result = try await api.fetchTrackedMedia(limit: 100)
            await MainActor.run {
                trackedMedia = result.items
            }
        } catch {
            // Non-critical, health is more important
        }
    }

    private func loadRecentJobs() async {
        do {
            let result = try await api.fetchJobs(status: "completed", limit: 10)
            await MainActor.run {
                recentJobs = result.items
            }
        } catch {
            // Non-critical
        }
    }

    private func loadFailedJobs() async {
        do {
            let result = try await api.fetchJobs(status: "failed", limit: 20)
            await MainActor.run {
                failedJobsList = result.items
            }
        } catch {
            // Non-critical
        }
    }

    func triggerDiscovery() async {
        isTriggering = true
        triggerMessage = nil
        do {
            let response = try await api.triggerDiscovery()
            await MainActor.run {
                triggerMessage = response.message
            }
            await loadAll()
        } catch {
            await MainActor.run {
                triggerMessage = "Error: \(error.localizedDescription)"
            }
        }
        await MainActor.run { isTriggering = false }
    }

    func triggerMonitor() async {
        isTriggering = true
        triggerMessage = nil
        do {
            let response = try await api.triggerMonitor()
            await MainActor.run {
                triggerMessage = response.message
            }
            await loadAll()
        } catch {
            await MainActor.run {
                triggerMessage = "Error: \(error.localizedDescription)"
            }
        }
        await MainActor.run { isTriggering = false }
    }

    func triggerProcess() async {
        isTriggering = true
        triggerMessage = nil
        do {
            let response = try await api.triggerProcess()
            await MainActor.run {
                triggerMessage = response.message
            }
            await loadAll()
        } catch {
            await MainActor.run {
                triggerMessage = "Error: \(error.localizedDescription)"
            }
        }
        await MainActor.run { isTriggering = false }
    }

    func mediaTitle(for mediaId: String) -> String {
        trackedMedia.first(where: { $0.mediaId == mediaId })?.title ?? mediaId
    }
}
