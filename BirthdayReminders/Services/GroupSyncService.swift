@preconcurrency import Contacts
import SwiftData
import os

/// Service for bidirectional sync between iOS Contacts groups (CNGroup) and SwiftData BirthdayGroup models.
///
/// Handles full CRUD for groups (create, rename, delete) and membership management
/// (add/remove contacts). Each mutation writes to both the iOS Contacts store via
/// CNSaveRequest and the local SwiftData model.
///
/// IMPORTANT: No URLSession or Network imports (SECR-01).
/// IMPORTANT: All group/contact data logged with privacy: .private (SECR-04).
@MainActor
final class GroupSyncService {
    private let store = CNContactStore()

    // MARK: - Group CRUD

    /// Create a new group in the default Contacts container and SwiftData.
    ///
    /// The CNGroup identifier is assigned by the Contacts store during execute(),
    /// so it is read after the save request completes.
    ///
    /// - Parameters:
    ///   - name: The display name for the new group.
    ///   - context: The SwiftData ModelContext to insert the BirthdayGroup into.
    /// - Returns: The newly created BirthdayGroup.
    @discardableResult
    func createGroup(name: String, context: ModelContext) throws -> BirthdayGroup {
        let mutableGroup = CNMutableGroup()
        mutableGroup.name = name

        let saveRequest = CNSaveRequest()
        saveRequest.add(mutableGroup, toContainerWithIdentifier: nil) // nil = default container
        try store.execute(saveRequest)

        // Identifier is populated after execute
        let birthdayGroup = BirthdayGroup(
            groupIdentifier: mutableGroup.identifier,
            name: name
        )
        context.insert(birthdayGroup)

        Logger.groups.info("Created group: \(name, privacy: .private) (\(mutableGroup.identifier, privacy: .private))")
        return birthdayGroup
    }

    /// Rename an existing group in both iOS Contacts and SwiftData.
    ///
    /// Re-fetches the CNGroup by identifier before mutation to avoid stale reference issues.
    ///
    /// - Parameters:
    ///   - group: The BirthdayGroup to rename.
    ///   - newName: The new display name.
    ///   - context: The SwiftData ModelContext (unused but kept for API consistency).
    func renameGroup(_ group: BirthdayGroup, to newName: String, context: ModelContext) throws {
        guard let cnGroup = try fetchCNGroup(identifier: group.groupIdentifier) else {
            Logger.groups.error("CNGroup not found for rename: \(group.groupIdentifier, privacy: .private)")
            return
        }

        let mutableGroup = cnGroup.mutableCopy() as! CNMutableGroup
        mutableGroup.name = newName

        let saveRequest = CNSaveRequest()
        saveRequest.update(mutableGroup)
        try store.execute(saveRequest)

        group.name = newName
        Logger.groups.info("Renamed group to: \(newName, privacy: .private)")
    }

    /// Delete a group from both iOS Contacts and SwiftData.
    ///
    /// The .nullify delete rule on BirthdayGroup.members preserves Person records.
    ///
    /// - Parameters:
    ///   - group: The BirthdayGroup to delete.
    ///   - context: The SwiftData ModelContext to delete from.
    func deleteGroup(_ group: BirthdayGroup, context: ModelContext) throws {
        guard let cnGroup = try fetchCNGroup(identifier: group.groupIdentifier) else {
            Logger.groups.error("CNGroup not found for delete: \(group.groupIdentifier, privacy: .private)")
            // Still remove from SwiftData even if CNGroup is already gone
            context.delete(group)
            return
        }

        let mutableGroup = cnGroup.mutableCopy() as! CNMutableGroup
        let saveRequest = CNSaveRequest()
        saveRequest.delete(mutableGroup)
        try store.execute(saveRequest)

        context.delete(group)
        Logger.groups.info("Deleted group: \(group.name, privacy: .private)")
    }

    // MARK: - Membership Management

    /// Add a person to a group in both iOS Contacts and SwiftData.
    ///
    /// - Parameters:
    ///   - person: The Person to add.
    ///   - group: The BirthdayGroup to add the person to.
    func addMember(_ person: Person, to group: BirthdayGroup) throws {
        guard let cnGroup = try fetchCNGroup(identifier: group.groupIdentifier) else {
            Logger.groups.error("CNGroup not found for addMember: \(group.groupIdentifier, privacy: .private)")
            return
        }
        guard let cnContact = try fetchCNContact(identifier: person.contactIdentifier) else {
            Logger.groups.error("CNContact not found for addMember: \(person.contactIdentifier, privacy: .private)")
            return
        }

        let saveRequest = CNSaveRequest()
        saveRequest.addMember(cnContact, to: cnGroup)
        try store.execute(saveRequest)

        group.members.append(person)
        Logger.groups.info("Added member \(person.contactIdentifier, privacy: .private) to group \(group.name, privacy: .private)")
    }

    /// Remove a person from a group in both iOS Contacts and SwiftData.
    ///
    /// - Parameters:
    ///   - person: The Person to remove.
    ///   - group: The BirthdayGroup to remove the person from.
    func removeMember(_ person: Person, from group: BirthdayGroup) throws {
        guard let cnGroup = try fetchCNGroup(identifier: group.groupIdentifier) else {
            Logger.groups.error("CNGroup not found for removeMember: \(group.groupIdentifier, privacy: .private)")
            return
        }
        guard let cnContact = try fetchCNContact(identifier: person.contactIdentifier) else {
            Logger.groups.error("CNContact not found for removeMember: \(person.contactIdentifier, privacy: .private)")
            return
        }

        let saveRequest = CNSaveRequest()
        saveRequest.removeMember(cnContact, from: cnGroup)
        try store.execute(saveRequest)

        group.members.removeAll { $0.contactIdentifier == person.contactIdentifier }
        Logger.groups.info("Removed member \(person.contactIdentifier, privacy: .private) from group \(group.name, privacy: .private)")
    }

    // MARK: - Bidirectional Sync

    /// Sync all groups from iOS Contacts into SwiftData.
    ///
    /// Fetches all CNGroups from all containers, upserts BirthdayGroup records,
    /// removes stale groups, and syncs membership for each group.
    /// Membership is assigned in one operation per group to avoid the SwiftData
    /// many-to-many append performance issue (750x slower with individual appends).
    ///
    /// - Parameter context: The SwiftData ModelContext to sync into.
    func syncGroupsFromContacts(context: ModelContext) throws {
        // Fetch all CNGroups from all containers
        let cnGroups = try store.groups(matching: nil)

        var seenIdentifiers = Set<String>()

        for cnGroup in cnGroups {
            seenIdentifiers.insert(cnGroup.identifier)

            let identifier = cnGroup.identifier
            let descriptor = FetchDescriptor<BirthdayGroup>(
                predicate: #Predicate { $0.groupIdentifier == identifier }
            )

            let birthdayGroup: BirthdayGroup
            if let existing = try context.fetch(descriptor).first {
                // Update name if changed
                if existing.name != cnGroup.name {
                    existing.name = cnGroup.name
                }
                birthdayGroup = existing
            } else {
                // New group from iOS Contacts
                let newGroup = BirthdayGroup(
                    groupIdentifier: cnGroup.identifier,
                    name: cnGroup.name
                )
                context.insert(newGroup)
                birthdayGroup = newGroup
            }

            // Sync membership: fetch contacts in this CNGroup and match to Person records
            let predicate = CNContact.predicateForContactsInGroup(withIdentifier: cnGroup.identifier)
            let keys = ContactBridge.keysToFetch()
            let cnContacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
            let memberIdentifiers = Set(cnContacts.map(\.identifier))

            let allPeople = try context.fetch(FetchDescriptor<Person>())
            let members = allPeople.filter { memberIdentifiers.contains($0.contactIdentifier) }

            // Assign in one operation to avoid repeated append performance issue
            birthdayGroup.members = members
        }

        // Remove stale BirthdayGroup records
        let allGroups = try context.fetch(FetchDescriptor<BirthdayGroup>())
        for group in allGroups {
            if !seenIdentifiers.contains(group.groupIdentifier) {
                context.delete(group)
            }
        }

        Logger.groups.info("Synced \(cnGroups.count) groups from iOS Contacts")
    }

    // MARK: - Private Helpers

    /// Re-fetch a fresh CNGroup by identifier to avoid stale reference issues.
    private func fetchCNGroup(identifier: String) throws -> CNGroup? {
        let predicate = CNGroup.predicateForGroups(withIdentifiers: [identifier])
        return try store.groups(matching: predicate).first
    }

    /// Fetch a CNContact by identifier for membership operations.
    private func fetchCNContact(identifier: String) throws -> CNContact? {
        let predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])
        let keys = ContactBridge.keysToFetch()
        return try store.unifiedContacts(matching: predicate, keysToFetch: keys).first
    }
}
