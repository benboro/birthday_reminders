import SwiftUI
import Contacts
import ContactsUI

/// UIViewControllerRepresentable wrapping CNContactViewController for "Open in Contacts".
///
/// Fetches the contact by identifier from CNContactStore and presents the native
/// iOS contact editor. Allows editing (so the user can fix birthdays in the single
/// source of truth) but disables actions (no call/message per user decision).
///
/// If the contact has been deleted since import, shows a graceful error state.
struct ContactDetailBridge: UIViewControllerRepresentable {
    let contactIdentifier: String
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let store = CNContactStore()
        let navController = UINavigationController()

        do {
            let keys = [CNContactViewController.descriptorForRequiredKeys()]
            let contact = try store.unifiedContact(
                withIdentifier: contactIdentifier,
                keysToFetch: keys
            )
            let contactVC = CNContactViewController(for: contact)
            contactVC.allowsEditing = true
            contactVC.allowsActions = false
            contactVC.delegate = context.coordinator
            navController.viewControllers = [contactVC]
        } catch {
            // Contact was deleted since import -- show a placeholder
            let errorVC = UIViewController()
            errorVC.view.backgroundColor = .systemBackground
            let label = UILabel()
            label.text = "Contact not found.\nIt may have been deleted."
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            errorVC.view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: errorVC.view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: errorVC.view.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: errorVC.view.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(lessThanOrEqualTo: errorVC.view.trailingAnchor, constant: -20),
            ])
            errorVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: context.coordinator,
                action: #selector(Coordinator.doneTapped)
            )
            navController.viewControllers = [errorVC]
        }

        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // Static content -- no updates needed
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, CNContactViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func contactViewController(
            _ viewController: CNContactViewController,
            didCompleteWith contact: CNContact?
        ) {
            dismiss()
        }

        @objc func doneTapped() {
            dismiss()
        }
    }
}
