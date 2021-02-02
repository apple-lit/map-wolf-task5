//
//  LoginTextField.swift
//  MapWolf-ios
//
//  Created by Masakaz Ozaki on 2021/01/22.
//

import SFSafeSymbols
import SwiftUI
import UIKit

struct LoginTextField: View {
    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType?
    var keyboardType: UIKeyboardType?
    let order: LoginTextFieldOrder
    let onCommitHandler: (() -> Void)?

    @State private var isSecureTextEntry = false

    var body: some View {
        VStack {
            ZStack {
                FocusChangableTextField(
                    configuration: Configuration(
                        text: self.$text,
                        placeholder: self.placeholder,
                        textContentType: self.textContentType,
                        order: self.order.rawValue,
                        autocorrectionType: .no,
                        autocapitalizationType: .none,
                        keyboardType: keyboardType,
                        isSecureTextEntry: $isSecureTextEntry,
                        onCommitHandler: self.onCommitHandler)
                )
                .frame(maxWidth: .infinity)
                HStack {
                    Spacer()
                    if textContentType == .password {
                        Button(action: {
                            isSecureTextEntry.toggle()
                        }) {
                            Image(systemSymbol: isSecureTextEntry ? .eyeSlashFill : .eyeFill)
                                .font(Font.system(.body).bold())
                        }
                    }

                    if text.isEmpty == false {
                        Button(action: {
                            text = ""
                        }) {
                            Image(systemSymbol: .xmarkCircleFill)
                                .font(Font.system(.body).bold())
                        }
                    }
                }
                .accentColor(Color(.systemGray2))
            }
            .padding(.horizontal)

            SwitchableGradientView(isGradient: text.isEmpty == false)
                .frame(height: 2)
                .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
        }
        .onAppear {
            if textContentType == .password {
                isSecureTextEntry = true
            }
        }
    }

    // MARK: - Underline

    private struct SwitchableGradientView: View {
        let isGradient: Bool

        let gradientShape = LinearGradient(
            gradient: Gradient(colors: [
                Color(Asset.Colors.mwPink.color),
                Color(Asset.Colors.mwPink.color)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
        var body: some View {
            HStack {
                if isGradient {
                    gradientShape
                } else {
                    Rectangle()
                        .foregroundColor(Color(.systemGray2))
                }
            }
        }
    }

    private struct HorizontalLineShape: Shape {
        func path(in rect: CGRect) -> Path {
            let fill = CGRect(
                x: -rect.size.width, y: 0, width: rect.size.width, height: rect.size.height)
            var path = Path()
            path.addRoundedRect(in: fill, cornerSize: CGSize(width: 2, height: 2))

            return path
        }
    }

    // MARK: - TextField

    /**
     This textField is designed to be used with the listed textFields. Pressing the return key will make the next textField the first responder.

     - Parameter tag: the order of text fields
     */

    private struct FocusChangableTextField: UIViewRepresentable {
        class Coordinator: NSObject, UITextFieldDelegate {
            let configuration: Configuration

            init(configuration: Configuration) {
                self.configuration = configuration
            }

            func textFieldDidChangeSelection(_ textField: UITextField) {
                self.configuration.text = textField.text ?? ""
            }

            func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                if let nextField = textField.superview?.superview?.viewWithTag(textField.tag + 1)
                    as? UITextField {
                    nextField.becomeFirstResponder()
                } else {
                    configuration.onCommitHandler?()
                    textField.resignFirstResponder()
                }
                return false
            }
        }

        let configuration: Configuration

        func makeUIView(context: UIViewRepresentableContext<FocusChangableTextField>) -> UITextField {
            let textField = UITextField(frame: .zero)
            textField.delegate = context.coordinator
            textField.setContentHuggingPriority(.required, for: .vertical)
            return textField
        }

        func makeCoordinator() -> FocusChangableTextField.Coordinator {
            return Coordinator(configuration: configuration)
        }

        func updateUIView(
            _ textField: UITextField, context: UIViewRepresentableContext<FocusChangableTextField>
        ) {
            textField.text = self.configuration.text
            textField.placeholder = self.configuration.placeholder
            textField.textContentType = self.configuration.textContentType
            textField.tag = self.configuration.order
            textField.autocorrectionType = self.configuration.autocorrectionType
            textField.autocapitalizationType = self.configuration.autocapitalizationType
            if let keyboardType = self.configuration.keyboardType {
                textField.keyboardType = keyboardType
            }

            textField.isSecureTextEntry = self.configuration.isSecureTextEntry
        }
    }

    // MARK: - Configuration

    private struct Configuration {
        @Binding var text: String
        let placeholder: String
        let textContentType: UITextContentType?
        let order: Int
        let autocorrectionType: UITextAutocorrectionType
        let autocapitalizationType: UITextAutocapitalizationType
        let keyboardType: UIKeyboardType?
        @Binding var isSecureTextEntry: Bool
        let onCommitHandler: (() -> Void)?
    }

    enum LoginTextFieldOrder: Int {
        case id
        case avatar
    }
}

struct LoginTextField_Previews: PreviewProvider {
    static var previews: some View {
        LoginTextField(
            placeholder: "ID", text: .constant("hogehoge"), textContentType: .username,
            keyboardType: .alphabet, order: .id, onCommitHandler: nil)
    }
}
