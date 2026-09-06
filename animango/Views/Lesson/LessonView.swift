import SwiftUI
import SwiftData

struct LessonView: View {
    let lesson: Lesson
    @State private var viewModel = LessonViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: viewModel.progress)
                .tint(.accentColor)
                .padding(.horizontal)
                .padding(.top, 8)

            if viewModel.isLessonComplete {
                lessonCompleteView
            } else if viewModel.showingGrammarIntro {
                grammarIntroView
            } else if let exercise = viewModel.currentExercise {
                if exercise.exerciseType == .pronunciation {
                    PronunciationExerciseView(
                        exercise: exercise,
                        onComplete: { score in
                            viewModel.pronunciationCompleted(score: score)
                        }
                    )
                } else {
                    LessonExerciseView(
                        exercise: exercise,
                        userAnswer: $viewModel.userAnswer,
                        isRevealed: viewModel.isAnswerRevealed,
                        onCheck: { viewModel.checkAnswer() },
                        onNext: { viewModel.nextExercise() }
                    )
                }
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadLesson(lesson, modelContext: modelContext)
        }
    }

    private var grammarIntroView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                if let grammar = viewModel.grammarPoint {
                    VStack(spacing: 12) {
                        Text(grammar.pattern)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(grammar.explanation)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if !grammar.examples.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Examples")
                                    .font(.headline)

                                ForEach(grammar.examples, id: \.japanese) { example in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(example.japanese)
                                            .font(.body)
                                        Text(example.reading)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(example.english)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                }

                Spacer(minLength: 20)

                Button {
                    viewModel.startExercises()
                } label: {
                    Text("Start Exercises")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    private var lessonCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Lesson Complete!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                Text("\(viewModel.correctCount) / \(viewModel.totalAttempted) correct")
                    .font(.title2)

                let percentage = viewModel.totalAttempted > 0
                    ? Int(Double(viewModel.correctCount) / Double(viewModel.totalAttempted) * 100)
                    : 0
                Text("\(percentage)% accuracy")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let grammar = viewModel.grammarPoint {
                Text("Grammar studied: \(grammar.pattern)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
