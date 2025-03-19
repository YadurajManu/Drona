//
//  StudyPlansView.swift
//  Drona
//
//  Created by Yaduraj Singh on 22/03/25.
//

import SwiftUI

struct StudyPlansView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var coachManager = StudyCoachManager.shared
    @State private var showingCreateSheet = false
    @State private var selectedPlan: StudyCoach.StudyPlan? = nil
    @State private var showCompletedPlans = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter toggle
                HStack {
                    Toggle("Show Completed Plans", isOn: $showCompletedPlans)
                        .font(.subheadline)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                if filteredPlans.isEmpty {
                    emptyStateView
                } else {
                    plansList
                }
            }
            .navigationTitle("Study Plans")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: {
                    showingCreateSheet = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingCreateSheet) {
                CreatePlanView()
            }
            .sheet(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
        }
    }
    
    private var plansList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredPlans) { plan in
                    PlanCard(plan: plan)
                        .onTapGesture {
                            selectedPlan = plan
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("No study plans yet")
                .font(.headline)
            
            Text("Create a study plan to organize your learning goals and track your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingCreateSheet = true
            }) {
                Text("Create Study Plan")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var filteredPlans: [StudyCoach.StudyPlan] {
        if showCompletedPlans {
            return coachManager.studyPlans
        } else {
            return coachManager.studyPlans.filter { !$0.isCompleted }
        }
    }
}

struct PlanCard: View {
    let plan: StudyCoach.StudyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                categoryTag
                
                Spacer()
                
                if plan.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else if let targetDate = plan.targetDate, targetDate < Date() {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else {
                    Text(dueText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(plan.title)
                .font(.headline)
            
            Text(plan.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Progress bar
            ProgressView(value: plan.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .padding(.vertical, 5)
            
            HStack {
                Text("\(completedTaskCount)/\(plan.tasks.count) tasks completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Difficulty: \(difficultyString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var categoryTag: some View {
        Text(plan.category)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
    
    private var progressColor: Color {
        if plan.isCompleted {
            return .green
        } else if let targetDate = plan.targetDate, targetDate < Date() {
            return .red
        } else if plan.progress < 0.4 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var completedTaskCount: Int {
        return plan.tasks.filter { $0.isCompleted }.count
    }
    
    private var difficultyString: String {
        switch plan.difficulty {
        case 1: return "Easy"
        case 2: return "Light"
        case 3: return "Moderate"
        case 4: return "Challenging"
        case 5: return "Difficult"
        default: return "Moderate"
        }
    }
    
    private var dueText: String {
        if let targetDate = plan.targetDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            return "Due \(formatter.localizedString(for: targetDate, relativeTo: Date()))"
        } else {
            return "No due date"
        }
    }
}

struct CreatePlanView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var coachManager = StudyCoachManager.shared
    
    @State private var subject = ""
    @State private var difficulty = 3
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(60 * 60 * 24 * 7) // 1 week from now
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subject")) {
                    TextField("What do you want to study?", text: $subject)
                }
                
                Section(header: Text("Difficulty")) {
                    Picker("Select difficulty level", selection: $difficulty) {
                        Text("Easy").tag(1)
                        Text("Light").tag(2)
                        Text("Moderate").tag(3)
                        Text("Challenging").tag(4)
                        Text("Difficult").tag(5)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Deadline")) {
                    Toggle("Set a deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Due date", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }
                }
                
                Section {
                    Button(action: generatePlan) {
                        if isGenerating {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 5)
                                Text("Generating...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray)
                            .cornerRadius(10)
                        } else {
                            Text("Generate Study Plan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(subject.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isGenerating || subject.isEmpty)
                }
            }
            .navigationTitle("Create Study Plan")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func generatePlan() {
        guard !subject.isEmpty else { return }
        
        isGenerating = true
        
        coachManager.generateStudyPlan(
            for: subject,
            difficulty: difficulty,
            deadline: hasDeadline ? deadline : nil
        )
        
        // Simulate a delay before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isGenerating = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PlanDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var coachManager = StudyCoachManager.shared
    
    let plan: StudyCoach.StudyPlan
    @State private var updatedPlan: StudyCoach.StudyPlan
    @State private var timeSpent: Int?
    @State private var selectedTask: StudyCoach.StudyPlan.StudyTask?
    
    init(plan: StudyCoach.StudyPlan) {
        self.plan = plan
        _updatedPlan = State(initialValue: plan)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    planHeader
                    
                    Divider()
                    
                    // Tasks
                    planTasks
                }
                .padding()
            }
            .navigationTitle("Study Plan")
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: planStatus
            )
            .sheet(item: $selectedTask) { task in
                TaskCompletionSheet(task: task, timeSpent: $timeSpent) { completedTask in
                    completeTask(completedTask)
                }
            }
        }
    }
    
    private var planHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress bar
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Progress: \(Int(updatedPlan.progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if !updatedPlan.isCompleted {
                        Text(dueText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ProgressView(value: updatedPlan.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
            }
            
            // Plan details
            Text(updatedPlan.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(updatedPlan.description)
                .foregroundColor(.secondary)
        }
    }
    
    private var planTasks: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tasks")
                .font(.headline)
            
            ForEach(updatedPlan.tasks) { task in
                taskRow(task)
            }
        }
    }
    
    private func taskRow(_ task: StudyCoach.StudyPlan.StudyTask) -> some View {
        Button(action: {
            if !task.isCompleted {
                selectedTask = task
            }
        }) {
            HStack(alignment: .top) {
                // Checkbox
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.system(size: 22))
                    .frame(width: 24, height: 24)
                
                // Task details
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .strikethrough(task.isCompleted)
                    
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack {
                        // Estimated time
                        HStack(spacing: 2) {
                            Image(systemName: "clock")
                                .font(.caption)
                            
                            Text("Est: \(task.estimatedMinutes) min")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        // Actual time if completed
                        if let actualTime = task.actualMinutes {
                            HStack(spacing: 2) {
                                Image(systemName: "hourglass")
                                    .font(.caption)
                                
                                Text("Actual: \(actualTime) min")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        // Due date if set
                        if let deadline = task.deadline {
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                
                                Text(formatDate(deadline))
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
            .opacity(task.isCompleted ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var planStatus: some View {
        if updatedPlan.isCompleted {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Completed")
            }
            .foregroundColor(.green)
        } else {
            Button(action: markPlanAsCompleted) {
                Text("Complete")
            }
        }
    }
    
    private var progressColor: Color {
        if updatedPlan.isCompleted {
            return .green
        } else if let targetDate = updatedPlan.targetDate, targetDate < Date() {
            return .red
        } else if updatedPlan.progress < 0.4 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var dueText: String {
        if let targetDate = updatedPlan.targetDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            return "Due \(formatter.localizedString(for: targetDate, relativeTo: Date()))"
        } else {
            return "No due date"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func completeTask(_ task: StudyCoach.StudyPlan.StudyTask) {
        if let index = updatedPlan.tasks.firstIndex(where: { $0.id == task.id }) {
            coachManager.completeTask(planId: updatedPlan.id, taskId: task.id, timeSpent: timeSpent)
            
            // Update local plan (will be updated from manager later)
            var newPlan = updatedPlan
            newPlan.tasks[index].isCompleted = true
            newPlan.tasks[index].actualMinutes = timeSpent
            
            // Update progress
            let totalTasks = newPlan.tasks.count
            let completedTasks = newPlan.tasks.filter { $0.isCompleted }.count
            newPlan.progress = Double(completedTasks) / Double(totalTasks)
            
            // Check if plan is complete
            if newPlan.progress >= 1.0 {
                newPlan.isCompleted = true
            }
            
            updatedPlan = newPlan
        }
    }
    
    private func markPlanAsCompleted() {
        var newPlan = updatedPlan
        newPlan.isCompleted = true
        newPlan.progress = 1.0
        
        // Mark all tasks as complete
        for i in 0..<newPlan.tasks.count {
            if !newPlan.tasks[i].isCompleted {
                newPlan.tasks[i].isCompleted = true
            }
        }
        
        coachManager.updateStudyPlan(newPlan)
        updatedPlan = newPlan
    }
}

struct TaskCompletionSheet: View {
    @Environment(\.presentationMode) var presentationMode
    let task: StudyCoach.StudyPlan.StudyTask
    @Binding var timeSpent: Int?
    let onComplete: (StudyCoach.StudyPlan.StudyTask) -> Void
    
    @State private var selectedTime: Int = 0
    @State private var sliderValue: Double = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Task info
                VStack(alignment: .leading, spacing: 10) {
                    Text(task.title)
                        .font(.headline)
                    
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Time spent
                VStack(spacing: 12) {
                    Text("How long did you spend on this task?")
                        .font(.headline)
                    
                    Text("\(selectedTime) minutes")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Slider(value: $sliderValue, in: 0...120, step: 5)
                        .onChange(of: sliderValue) { newValue in
                            selectedTime = Int(newValue)
                        }
                    
                    HStack {
                        Text("0 min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("2 hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Preset buttons
                    HStack {
                        ForEach([15, 30, 45, 60], id: \.self) { minutes in
                            Button(action: {
                                selectedTime = minutes
                                sliderValue = Double(minutes)
                            }) {
                                Text("\(minutes)")
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedTime == minutes ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(selectedTime == minutes ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Complete button
                Button(action: {
                    timeSpent = selectedTime
                    onComplete(task)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Mark as Completed")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding()
            .navigationBarTitle("Complete Task", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                // Set initial value to estimated time
                selectedTime = task.estimatedMinutes
                sliderValue = Double(task.estimatedMinutes)
            }
        }
    }
}

struct StudyPlansView_Previews: PreviewProvider {
    static var previews: some View {
        StudyPlansView()
    }
} 