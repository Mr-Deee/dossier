/**
 * The Dossier — Cloud Functions (Legacy Switch & Life Check).
 *
 * These functions never see user data in plaintext: records and category keys
 * are encrypted on the user's device. What the server controls is *when* a
 * confidant's sealed grant becomes readable:
 *
 *   request created ─► owner notified, objection window starts
 *                   ─► verifier(s) independently confirm the event
 *                   ─► after the window, with no objection and no owner
 *                      check-in, the grant is marked "released"
 *
 * A missed Life Check never releases anything.
 */
import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {CallableRequest, HttpsError, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as functionsV1 from "firebase-functions/v1";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";

// Must match `functionsRegion` in lib/core/services/firebase_refs.dart.
const REGION = "europe-west1";
setGlobalOptions({region: REGION, maxInstances: 10});
initializeApp();
const db = getFirestore();

const DAY_MS = 24 * 60 * 60 * 1000;
const OBJECTION_DAYS: Record<string, number> = {death: 14, incapacity: 7};
/** Separation of duties: distinct verifiers that must approve a release. */
const REQUIRED_APPROVALS = Math.max(1, Number(process.env.REQUIRED_APPROVALS ?? "2"));
const LIFE_CHECK_ESCALATE_AFTER = 3;

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

async function audit(ownerUid: string, action: string, target?: string): Promise<void> {
  await db.collection(`users/${ownerUid}/audit`).add({
    at: FieldValue.serverTimestamp(),
    actor: "system",
    action,
    ...(target ? {target} : {}),
  });
}

/** In-app notification + optional email via the "Trigger Email" extension (`mail` collection). */
async function notify(uid: string, title: string, body: string): Promise<void> {
  await db.collection(`users/${uid}/notifications`).add({
    title,
    body,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
  try {
    const user = await getAuth().getUser(uid);
    if (user.email) {
      await db.collection("mail").add({to: user.email, message: {subject: `The Dossier: ${title}`, text: body}});
    }
  } catch {
    /* user deleted or no email */
  }
}

function requireVerifier(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  if (req.auth.token.verifier !== true) throw new HttpsError("permission-denied", "Verifier role required.");
  return req.auth.uid;
}

function parseDecision(req: CallableRequest): {requestId: string; note: string} {
  const {requestId, note} = (req.data ?? {}) as {requestId?: unknown; note?: unknown};
  if (typeof requestId !== "string" || !requestId) throw new HttpsError("invalid-argument", "requestId required.");
  if (typeof note !== "string" || note.trim().length < 10) {
    throw new HttpsError("invalid-argument", "A verification note of at least 10 characters is required.");
  }
  return {requestId, note: note.trim().slice(0, 2000)};
}

// ---------------------------------------------------------------------------
// Access request created → start objection window, alert owner
// ---------------------------------------------------------------------------

export const onAccessRequestCreated = onDocumentCreated("accessRequests/{id}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const r = snap.data();
  const days = OBJECTION_DAYS[r.circumstance as string] ?? 14;
  const deadline = Timestamp.fromMillis(Date.now() + days * DAY_MS);
  await snap.ref.update({objectionDeadline: deadline, approvals: []});
  await audit(r.ownerUid, "request.created", snap.id);
  await notify(
    r.ownerUid,
    "Someone has requested access to your Dossier",
    `A trusted confidant has reported "${r.circumstance}" and requested access. If you are well, open The Dossier ` +
      `and tap "Object" (or simply complete your Life Check) before ${deadline.toDate().toUTCString()}. ` +
      "Nothing is released while you can still object.",
  );
});

// ---------------------------------------------------------------------------
// Verifier approves → (after N distinct approvals) release the grant
// ---------------------------------------------------------------------------

export const approveAccessRequest = onCall(async (req) => {
  const verifierUid = requireVerifier(req);
  const {requestId, note} = parseDecision(req);

  const result = await db.runTransaction(async (tx) => {
    const ref = db.doc(`accessRequests/${requestId}`);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Request not found.");
    const r = snap.data()!;
    if (r.status !== "pending") throw new HttpsError("failed-precondition", `Request is ${r.status}.`);
    if (r.requesterUid === verifierUid || r.ownerUid === verifierUid) {
      throw new HttpsError("permission-denied", "You cannot verify a request you are party to.");
    }
    const deadline = r.objectionDeadline as Timestamp | undefined;
    if (!deadline || deadline.toMillis() > Date.now()) {
      throw new HttpsError("failed-precondition", "The owner's objection period has not ended yet.");
    }

    const grantRef = db.doc(`users/${r.ownerUid}/grants/${r.requesterUid}`);
    const ownerRef = db.doc(`users/${r.ownerUid}`);
    const [grant, owner] = await Promise.all([tx.get(grantRef), tx.get(ownerRef)]);
    if (!grant.exists) throw new HttpsError("failed-precondition", "The owner has not granted this person access.");
    const triggers: string[] = grant.data()!.triggers ?? [];
    if (!triggers.includes(r.circumstance)) {
      throw new HttpsError("failed-precondition", `The owner did not authorise release on ${r.circumstance}.`);
    }
    // Proof of life after the request blocks release.
    const lastCheckIn = owner.data()?.lifeCheck?.lastCheckIn as Timestamp | undefined;
    const createdAt = r.createdAt as Timestamp | undefined;
    if (lastCheckIn && createdAt && lastCheckIn.toMillis() > createdAt.toMillis()) {
      tx.update(ref, {
        status: "objected",
        objectionReason: "Owner completed a Life Check after the request was made.",
        decidedAt: FieldValue.serverTimestamp(),
      });
      return {released: false, blocked: true, approvals: 0};
    }

    const approvals: {uid: string; note: string; at: Timestamp}[] = r.approvals ?? [];
    if (approvals.some((a) => a.uid === verifierUid)) {
      throw new HttpsError("already-exists", "You have already approved this request. A different verifier must confirm.");
    }
    approvals.push({uid: verifierUid, note, at: Timestamp.now()});

    if (approvals.length < REQUIRED_APPROVALS) {
      tx.update(ref, {approvals});
      return {released: false, blocked: false, approvals: approvals.length};
    }
    tx.update(grantRef, {
      status: "released",
      releasedFor: r.circumstance,
      releasedAt: FieldValue.serverTimestamp(),
      releasedByRequest: requestId,
    });
    tx.update(ref, {
      approvals,
      status: "approved",
      decidedAt: FieldValue.serverTimestamp(),
      decisionNote: "Verified and released.",
    });
    return {released: true, blocked: false, approvals: approvals.length, ownerUid: r.ownerUid, requesterUid: r.requesterUid};
  });

  const reqSnap = await db.doc(`accessRequests/${requestId}`).get();
  const r = reqSnap.data()!;
  if (result.blocked) {
    await audit(r.ownerUid, "request.objected", requestId);
  } else if (result.released) {
    await audit(r.ownerUid, "request.approved", requestId);
    await notify(r.requesterUid, "Access released", "Your access request was verified. Open The Dossier → Shared with me.");
  }
  return {...result, required: REQUIRED_APPROVALS};
});

export const rejectAccessRequest = onCall(async (req) => {
  const verifierUid = requireVerifier(req);
  const {requestId, note} = parseDecision(req);
  const ref = db.doc(`accessRequests/${requestId}`);
  const r = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "Request not found.");
    const data = snap.data()!;
    if (data.status !== "pending") throw new HttpsError("failed-precondition", `Request is ${data.status}.`);
    tx.update(ref, {
      status: "rejected",
      decidedAt: FieldValue.serverTimestamp(),
      decidedBy: verifierUid,
      decisionNote: note,
    });
    return data;
  });
  await audit(r.ownerUid, "request.rejected", requestId);
  await notify(r.requesterUid, "Access request not approved", note);
  return {ok: true};
});

// ---------------------------------------------------------------------------
// Life Check sweep — reminders and escalation only. Never releases data.
// ---------------------------------------------------------------------------

export const lifeCheckSweep = onSchedule({schedule: "every day 08:00", timeZone: "Africa/Accra"}, async () => {
  const now = Timestamp.now();
  const due = await db
    .collection("users")
    .where("lifeCheck.enabled", "==", true)
    .where("lifeCheck.nextDue", "<=", now)
    .limit(500)
    .get();

  for (const doc of due.docs) {
    const lc = doc.data().lifeCheck ?? {};
    const paused = lc.pausedUntil as Timestamp | null | undefined;
    if (paused && paused.toMillis() > now.toMillis()) continue;

    const missed = (Number(lc.missed) || 0) + 1;
    await doc.ref.update({
      "lifeCheck.missed": missed,
      "lifeCheck.nextDue": Timestamp.fromMillis(now.toMillis() + 3 * DAY_MS), // escalate every 3 days
    });
    await audit(doc.id, "lifecheck.missed");
    await notify(doc.id, "Life Check reminder", "Please open The Dossier and confirm you are well.");

    if (missed === LIFE_CHECK_ESCALATE_AFTER) {
      // Alternative contact procedure: ask confidants to check on the owner.
      const noms = await db.collection("nominations").where("ownerUid", "==", doc.id).get();
      for (const n of noms.docs) {
        await notify(
          n.data().granteeUid,
          "Please check on someone who named you as a confidant",
          "A person who named you as a trusted confidant has missed several Life Checks. Please try to contact " +
            "them. This is not a notification of death, and no information has been released.",
        );
      }
    }
  }
});

// ---------------------------------------------------------------------------
// Account deletion — purge everything the client could not delete itself.
// ---------------------------------------------------------------------------

export const onUserDeleted = functionsV1.region(REGION).auth.user().onDelete(async (user) => {
  const uid = user.uid;
  await db.recursiveDelete(db.doc(`users/${uid}`));
  const batch = db.batch();
  const [dir, nomsOwner, nomsGrantee, grantsAsGrantee] = await Promise.all([
    db.collection("directory").where("uid", "==", uid).get(),
    db.collection("nominations").where("ownerUid", "==", uid).get(),
    db.collection("nominations").where("granteeUid", "==", uid).get(),
    db.collectionGroup("grants").where("granteeUid", "==", uid).get(),
  ]);
  [...dir.docs, ...nomsOwner.docs, ...nomsGrantee.docs, ...grantsAsGrantee.docs].forEach((d) => batch.delete(d.ref));
  await batch.commit();
  await getStorage().bucket().deleteFiles({prefix: `users/${uid}/`});
});
