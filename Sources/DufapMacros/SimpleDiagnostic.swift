//
//  SimpleDiagnostic.swift
//  Dufap
//
//  Created by Andrew Kuts on 2025-04-10.
//

import SwiftDiagnostics

struct SimpleDiagnostic: DiagnosticMessage {
    let message: String
    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID { MessageID(domain: "ActionMacro", id: message) }
}
