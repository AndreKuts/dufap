//
//  SimpleDiagnostic.swift
//  Dufap
//
//  Created by Andrew Kuts
//

import SwiftDiagnostics

struct SimpleDiagnostic: DiagnosticMessage {
    let message: String
    var severity: DiagnosticSeverity { .error }
    var diagnosticID: MessageID { MessageID(domain: "Dufap", id: message) }
}
