//
//  AboutView.swift
//  StepUp — privacy, data practices, credits.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Free forever", systemImage: "heart.fill")
                        .foregroundStyle(.pink)
                    Label("No ads", systemImage: "nosign")
                    Label("No subscription", systemImage: "creditcard.trianglebadge.exclamationmark")
                    Label("No tracking", systemImage: "eye.slash")
                } header: {
                    Text("Walk Up")
                } footer: {
                    Text("Walk Up is free, with no ads and no in-app purchases. The only data we touch is your step count, and only while the alarm is ringing.")
                }

                Section("Privacy") {
                    Link(destination: URL(string: "https://walkup.app/privacy")!) {
                        HStack {
                            Label("Privacy policy", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://walkup.app/support")!) {
                        HStack {
                            Label("Support", systemImage: "questionmark.circle")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("How it works") {
                    Label("CoreMotion counts your steps in real time.", systemImage: "figure.walk")
                    Label("Steps never leave your device.", systemImage: "lock.shield")
                    Label("You can long-press 3s to dismiss without walking.", systemImage: "hand.tap")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("About")
        }
    }
}