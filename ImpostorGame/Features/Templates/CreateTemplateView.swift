//
//  CreateTemplateView.swift
//  ImpostorGame
//
//  Created by Khalid Sh on 1/2/26.
//

import SwiftUI

struct CreateTemplateView: View {
    @State private var viewModel = TemplateViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    let onComplete: (Template) -> Void
    
    enum Field {
        case name, mainWord, impostorWord
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Template info section
                Section {
                    TextField(Constants.Strings.templateName, text: $viewModel.templateName)
                        .focused($focusedField, equals: .name)
                    
                    Toggle(Constants.Strings.makePublic, isOn: $viewModel.isPublic)
                } header: {
                    Text("معلومات القالب")
                } footer: {
                    Text("القوالب العامة يمكن للجميع استخدامها")
                }
                
                // Add word pair section
                Section {
                    HStack {
                        TextField(Constants.Strings.mainWord, text: $viewModel.currentMainWord)
                            .focused($focusedField, equals: .mainWord)
                        
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(.secondary)
                        
                        TextField(Constants.Strings.impostorWord, text: $viewModel.currentImpostorWord)
                            .focused($focusedField, equals: .impostorWord)
                    }
                    
                    Button {
                        viewModel.addWordPair()
                        focusedField = .mainWord
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(Constants.Strings.addWordPair)
                        }
                    }
                    .disabled(viewModel.currentMainWord.isEmpty || viewModel.currentImpostorWord.isEmpty)
                } header: {
                    Text("إضافة زوج كلمات")
                } footer: {
                    Text("الكلمة الرئيسية للاعبين العاديين، كلمة المخادع للمخادع")
                }
                
                // Word pairs list
                Section {
                    if viewModel.wordPairs.isEmpty {
                        Text("لم تضف أي كلمات بعد")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.wordPairs) { pair in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 8) {
                                        Text("الرئيسية:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(pair.main)
                                            .font(.headline)
                                    }
                                    
                                    HStack(spacing: 8) {
                                        Text("المخادع:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(pair.impostor)
                                            .font(.subheadline)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        .onDelete(perform: viewModel.removeWordPair)
                    }
                } header: {
                    HStack {
                        Text("الكلمات (\(viewModel.wordPairCount))")
                        Spacer()
                        if viewModel.remainingPairs > 0 {
                            Text("باقي \(viewModel.remainingPairs)")
                                .foregroundStyle(.orange)
                        } else {
                            Text("✓")
                                .foregroundStyle(.green)
                        }
                    }
                } footer: {
                    if viewModel.remainingPairs > 0 {
                        Text(Constants.Strings.minWordPairsRequired)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(Constants.Strings.createTemplate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Constants.Strings.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Constants.Strings.save) {
                        Task {
                            await viewModel.saveTemplate()
                        }
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
                }
            }
            .loadingOverlay(isLoading: viewModel.isLoading)
            .errorAlert(error: $viewModel.error)
            .onChange(of: viewModel.createdTemplate) { _, template in
                if let template = template {
                    onComplete(template)
                    dismiss()
                }
            }
        }
        .rtl()
    }
}

// MARK: - Template List View (for profile/management)
struct TemplateListView: View {
    @State private var templates: [Template] = []
    @State private var isLoading = true
    @State private var showingCreateTemplate = false
    
    var body: some View {
        List {
            ForEach(templates) { template in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        if template.isDefault {
                            Text("افتراضي")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        if template.isPublic {
                            Text("عام")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("\(template.words.count) كلمة")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("القوالب")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateTemplate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateTemplateView { newTemplate in
                templates.append(newTemplate)
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            await loadTemplates()
        }
        .rtl()
    }
    
    private func loadTemplates() async {
        do {
            templates = try await SupabaseService.shared.fetchTemplates()
            isLoading = false
        } catch {
            print("Failed to load templates: \(error)")
            isLoading = false
        }
    }
}

#Preview {
    CreateTemplateView { _ in }
}

