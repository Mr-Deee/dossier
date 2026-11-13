# The Dossier — Encryption & Access Design

**Goal:** Firestore and Cloud Storage hold only ciphertext. Data can be decrypted only inside the app, by a person
holding the right key. That means the account owner, or a confidant after a verified release. Google, Firebase console
users, The Dossier's own administrators and verifiers cannot read user records.

## 1. Key hierarchy

```
Vault passphrase ──Argon2id (19 MiB, t=2, p=1, 16-byte salt)──► KEK_pass ─┐
Recovery key (160-bit random, shown once) ──HKDF-SHA256──────► KEK_rec  ─┼─ AES-256-GCM wrap ─► Master Key (MK, 256-bit random)
                                                                          │
MK ── AES-256-GCM ─► Keyring { 6 category keys, X25519 identity private key }
Category key ── AES-256-GCM ─► every record in that pillar (life, wealth, vault, legacy, family, succession)
Per-file random key (stored inside the encrypted document record) ── AES-256-GCM ─► file in Cloud Storage
```

* **Two separate secrets.** The *account password* (Firebase Auth) proves identity to the server. The *vault
  passphrase* never leaves the device and is the root of encryption. Resetting the account password by email does not
  affect the vault.
* **Associated data (AAD)** binds every ciphertext to its context: `dossier/v1/record/<uid>/<category>/<recordId>`.
  A ciphertext copied to another record, category or account fails authentication.
* **What the server can see:** that an account exists, how many records it has in each pillar, timestamps, Life Check
  dates, and confidant relationships (who named whom, by uid). It cannot see names, values, file names, record types
  or file contents.
* **Rules enforce ciphertext.** `firestore.rules` rejects any record whose `blob` does not match the
  `g1.<nonce>.<ct>.<mac>` shape, so a bug can't silently store plaintext.

## 2. Unlocking

| Method | How |
|---|---|
| Passphrase | Argon2id runs on a background isolate, unwraps MK, opens keyring |
| Recovery key | Unwraps MK via `mkByRecovery`; the user then sets a new passphrase |
| Biometrics (optional) | MK stored in Android Keystore-backed EncryptedSharedPreferences / iOS Keychain (`unlocked_this_device`, not backed up), released after `local_auth` succeeds |

Keys are wiped from memory on lock, sign-out and auto-lock (default 5 min in background). Android sets `FLAG_SECURE`
(no screenshots or task-switcher previews) and `allowBackup="false"`. Decrypted files opened in an external viewer are
written to a private temp folder that is purged on lock and at startup.

**If a user loses both the passphrase and the recovery key, the data cannot be recovered.** This is inherent to
end-to-end encryption, and the setup screens say so before the vault is created.

## 3. Legacy Switch (sharing with confidants)

1. Each user publishes `directory/sha256(email) → {uid, X25519 public key}`. Rules only allow writing your own entry
   and only `get` (no listing).
2. The owner names a confidant, compares the confidant's **key fingerprint** out of band, and seals the selected
   category keys to that public key (ephemeral X25519 + HKDF-SHA256 + AES-256-GCM). The result is stored in
   `users/{owner}/grants/{confidant}` with `status: "sealed"`.
3. Rules keep the grant **and** the owner's records invisible to the confidant while `status != "released"`. Clients
   can never write `released`.
4. The confidant submits an access request with evidence. A Cloud Function starts the **objection window**
   (14 days for death, 7 for incapacity) and notifies the owner.
5. The release is blocked if the owner objects, or completes a Life Check after the request. It needs approval from
   **two distinct verifiers** (`REQUIRED_APPROVALS`, separation of duties) who are not party to the request, after the
   window closes, for a circumstance the owner authorised.
6. Only then does the function set `status: "released"`. The confidant's app opens the sealed keys and reads only the
   granted categories. Every view and file open is written to the owner's append-only audit log.
7. Incapacity releases can be re-sealed by the owner on recovery.

Verifiers hold no keys. They see the request, statement and evidence, never the records.

## 4. Residual risks & recommendations before launch

* **Evidence files are not end-to-end encrypted** (the verification team must read them). Storage rules limit them to
  the requester and verifiers.
* **Metadata** listed in §1 is visible to the server.
* **A compromised device while unlocked** exposes that user's data. Mitigations: auto-lock, FLAG_SECURE, biometric
  gating.
* **Directory trust:** fingerprint comparison defends against a malicious directory entry. Encourage users to do it.
* **Release is irreversible for what was already viewed**: re-sealing stops future reads only.
* **Enable Firebase App Check** (Play Integrity / App Attest) so only the genuine app can call Firebase.
* **Commission an independent security review/penetration test** and obtain legal advice on the Data Protection Act,
  2012 (Act 843), the Wills Act, 1971 (Act 360) and succession rules before production (blueprint §9.4).
* AI features run **on-device only**. Sending decrypted records to a cloud AI API would break E2EE. If you add cloud
  AI later, make it opt-in per record, with explicit consent.
