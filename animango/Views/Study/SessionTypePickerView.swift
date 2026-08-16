import SwiftUI

struct SessionTypePickerView: View {
    @Binding var selectedType: StudyItemType?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What to Study")
                .font(.headline)

            HStack(spacing: 12) {
                sessionTypeButton(type: nil, label: "Mixed", icon: "shuffle")

                ForEach(StudyItemType.allCases, id: \.rawValue) { type in
                    sessionTypeButton(type: type, label: type.displayName, icon: type.iconName)
                }
            }
        }
    }

    private func sessionTypeButton(type: StudyItemType?, label: String, icon: String) -> some View {
        let isSelected = selectedType == type

        return Button {
            selectedType = type
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    SessionTypePickerView(selectedType: .constant(nil))
        .padding()
}
