//
//  CTextField.swift
//  CarbonKit
//
//  Created by Miguel Fermin on 2/9/25.
//  Copyright © 2025 MAF Software LLC. All rights reserved.
//

import SwiftUI

public struct CTextField: View {
    let title: String
    let color = Color.secondary
    let validationType: ValidationType
    
    @Binding var text: String
    @Binding var validation: TextFieldValidationState
    
    @State private var hasEdited: Bool = false
    @State private var hasLooseFocus: Bool = false
    @State private var passwordHidden: Bool = true
    
    @FocusState private var isFocused: Bool
    
    private var withinForm: Bool
    
    public init(
        _ title: String,
        text: Binding<String>,
        validationType: ValidationType,
        validation: Binding<TextFieldValidationState> = .constant(.normal),
        withinForm: Bool = false
    ) {
        self.title = title
        self._text = text
        self.validationType = validationType
        self._validation = validation
        self.withinForm = withinForm
    }
    
    public var body: some View {
        HStack {
            ZStack {
                VStack(alignment: .leading) {
                    headerContent
                        .opacity(hasEdited ? 1 : 0)
                    
                    textFieldView
                        .keyboardType(validationType.keyboardType)
                        .textContentType(validationType.textContentType)
                        .textInputAutocapitalization(validationType.autocapitalization)
                        .autocorrectionDisabled(validationType.autocorrectionDisabled)
                        .focused($isFocused)
                        .foregroundColor(color)
                        .onChange(of: text) { _, newValue in
                            if !hasEdited && !text.isEmpty {
                                hasEdited = true
                            }
                            validation = validationType.validate(newValue)
                        }
                        .onChange(of: isFocused) { oldValue, newValue in
                            if !hasLooseFocus && !newValue {
                                hasLooseFocus = true
                                // probably hasn't typed, but leaving textfield is considered an edit
                                hasEdited = true
                                validation = validationType.validate(text)
                            }
                        }
                    
                    if !withinForm {
                        RoundedRectangle(cornerSize: .init(width: 1, height: 1))
                            .frame(height: isFocused ? 2 : 1)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(validation.borderColor(hasLooseFocus))
                    }
                }
                Spacer()
                
                HStack {
                    Spacer()
                    if withinForm && hasEdited && hasLooseFocus {
                        validation.view
                    }
                    if validationType.isPassword {
                        Image(systemName: passwordHidden ? "eye.slash.fill" : "eye.fill")
                            .onTapGesture { passwordHidden.toggle() }
                    }
                }
            }
        }
//        .frame(minHeight: 30)
    }
    
    @ViewBuilder
    private var headerContent: some View {
        if case .failed(let string) = validation, hasEdited, hasLooseFocus {
            HStack {
                Text(string)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
                Spacer()
            }
        } else  {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.vertical, 2)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var textFieldView: some View {
        if validationType.isPassword && passwordHidden {
            SecureField(title, text: $text)
        } else {
            TextField(title, text: $text, axis: .horizontal)
        }
    }
}

#Preview {
    @Previewable @State var name = ""
    @Previewable @State var email = ""
    @Previewable @State var password = ""
    @Previewable @State var nameValidation = TextFieldValidationState.normal
    @Previewable @State var emailValidation = TextFieldValidationState.normal
    @Previewable @State var passwordValidation = TextFieldValidationState.normal
    
    Form {
        CTextField(
            "First Name",
            text: $name,
            validationType: .firstName,
            validation: $nameValidation,
            withinForm: true
        )
        CTextField(
            "Email",
            text: $email,
            validationType: .email,
            validation: $emailValidation,
            withinForm: true
        )
        CTextField(
            "Password",
            text: $password,
            validationType: .password(.signup),
            validation: $passwordValidation,
            withinForm: true
        )
    }
}


// MARK: - ValidationType
public enum ValidationType {
    public enum Step {
        case signup
        case signin
    }
    
    case firstName
    case middleName
    case lastName
    case email
    case password(Step)
    case verificationCode
    
    var isPassword: Bool {
        switch self {
        case .password:
            return true
        default:
            return false
        }
    }
    
    var autocorrectionDisabled: Bool {
        return true
    }
    
    var autocapitalization: TextInputAutocapitalization? {
        switch self {
        case .firstName:
            return .words
        case .middleName:
            return .words
        case .lastName:
            return .words
        case .email:
            return .never
        case .password:
            return .never
        case .verificationCode:
            return .never
        }
    }
    
    var textContentType: UITextContentType? {
        switch self {
        case .firstName:
            return .givenName
        case .middleName:
            return .middleName
        case .lastName:
            return .familyName
        case .email:
            return .emailAddress
        case .password:
            return .password
        case .verificationCode:
            return .oneTimeCode
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .firstName:
            return .default
        case .middleName:
            return .default
        case .lastName:
            return .default
        case .email:
            return .emailAddress
        case .password:
            return .default
        case .verificationCode:
            return .numberPad
        }
    }
}

extension ValidationType {
    func validate(_ value: String) -> TextFieldValidationState {
        switch self {
        case .firstName:
            Self.validateFirstName(value)
        case .middleName:
            value.isEmpty ? .passed : .normal
        case .lastName:
            Self.validateLastName(value)
        case .email:
            Self.validateEmail(value)
        case .password(let step):
            switch step {
            case .signup:
                Self.validatePassword(value)
            case .signin:
                Self.validatePasswordForLogin(value)
            }
        case .verificationCode:
            Self.validateVerificationCode(value)
        }
    }
    
    private static func validateFirstName(_ firstName: String) -> TextFieldValidationState {
        if firstName.isEmpty {
            return .failed("Please enter first name")
        } else {
            return .passed
        }
    }
    
    private static func validateLastName(_ lastName: String) -> TextFieldValidationState {
        if lastName.isEmpty {
            return .failed("Please enter last name")
        } else {
            return .passed
        }
    }
    
    private static func validateEmail(_ email: String) -> TextFieldValidationState {
        if email.isEmail {
            return .passed
        } else if email.isEmpty {
            return .failed("Please enter email")
        } else {
            return .failed("Please enter valid email")
        }
    }
    
    private static func validatePassword(_ password: String) -> TextFieldValidationState {
        if password.isEmpty {
            return .failed("Please enter Password")
        } else if password.count < 8 {
            return .failed("Password must be at least 8 characters long")
        } else {
            return .passed
        }
    }
    
    private static func validatePasswordForLogin(_ password: String) -> TextFieldValidationState {
        password.isEmpty ? .failed("Please enter Password") : .passed
    }
    
    private static func validateVerificationCode(_ code: String) -> TextFieldValidationState {
        if code.isEmpty {
            .failed("Please enter verification code")
        } else if Int(code) == nil {
            .failed("Verification code must be numeric")
        } else if code.count != 6 {
            .failed("Verification code must be 6 character long")
        } else {
            .passed
        }
    }
}

// MARK: - TextFieldValidationState
public enum TextFieldValidationState: Equatable {
    case normal
    case passed
    case loading
    case failed(LocalizedStringKey)
    
    @ViewBuilder
    @MainActor
    var view: some View {
        switch self {
        case .normal:
            EmptyView()
        case .passed:
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .loading:
            Spacer()
            ProgressView()
        case .failed:
            Spacer()
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
    
    func borderColor(_ hasLooseFocus: Bool) -> Color {
        if !hasLooseFocus {
            return Color.secondary.opacity(0.6)
        }
        switch self {
        case .failed: return Color.red
        default: return Color.secondary.opacity(0.6)
        }
    }
}
