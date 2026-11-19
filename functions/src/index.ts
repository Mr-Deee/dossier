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
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {CallableRequest, HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as functionsV1 from "firebase-functions/v1";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, getFirestore, Timestamp} from "firebase-admin/firestore";
import {getStorage} from "firebase-admin/storage";
import {getMessaging} from "firebase-admin/messaging";
import {randomBytes} from "crypto";

// Must match `functionsRegion` in lib/core/services/firebase_refs.dart.
const REGION = "europe-west1";
setGlobalOptions({region: REGION, maxInstances: 10});
initializeApp();
const db = getFirestore();

const DAY_MS = 24 * 60 * 60 * 1000;
const OBJECTION_DAYS: Record<string, number> = {death: 14, incapacity: 7};
/**
 * TESTING ONLY: when set (e.g. OBJECTION_HOURS=1 in functions/.env), the
 * objection window is this many hours instead of the days above. Leave unset
 * in production.
 */
const OBJECTION_HOURS = Number(process.env.OBJECTION_HOURS ?? "0");
/** Separation of duties: distinct verifiers that must approve a release. */
const REQUIRED_APPROVALS = Math.max(1, Number(process.env.REQUIRED_APPROVALS ?? "2"));
const LIFE_CHECK_SWEEP = process.env.LIFE_CHECK_SWEEP || "every day 08:00";
/** Missed check-in at which confidants are asked whether the owner is around (after 3 warnings). */
const ASK_CONFIDANTS_AT = 4;
/** How long an emailed "is this person OK?" link stays valid. */
const LIFE_CHECK_LINK_DAYS = 14;

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

type Alert = {type?: string; id?: string};

/**
 * In-app notification (bell inbox), push notification to the user's devices
 * (arrives even when the app is closed) and optional email via the
 * "Trigger Email" extension (`mail` collection).
 */
async function notify(uid: string, title: string, body: string, data: Alert = {}): Promise<void> {
  await db.collection(`users/${uid}/notifications`).add({
    title,
    body,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
    ...(data.type ? {type: data.type} : {}),
    ...(data.id ? {refId: data.id} : {}),
  });
  await push(uid, title, body, data);
  try {
    const user = await getAuth().getUser(uid);
    if (user.email) {
      await db.collection("mail").add({to: user.email, message: {subject: `The Dossier: ${title}`, text: body}});
    }
  } catch {
    /* user deleted or no email */
  }
}

/** Sends a push notification to every device the user registered. Dead tokens are removed. */
async function push(uid: string, title: string, body: string, data: Alert): Promise<void> {
  try {
    const devices = await db.collection(`users/${uid}/devices`).get();
    if (devices.empty) return;
    const tokens = devices.docs.map((d) => d.data().token as string).filter(Boolean);
    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {title, body},
      data: {type: data.type ?? "alert", id: data.id ?? ""},
      android: {priority: "high", notification: {channelId: "dossier_alerts"}},
      apns: {payload: {aps: {sound: "default"}}},
    });
    const dead = res.responses
      .map((r, i) => (r.error?.code === "messaging/registration-token-not-registered" ||
        r.error?.code === "messaging/invalid-registration-token" ? devices.docs[i].ref : null))
      .filter((r): r is FirebaseFirestore.DocumentReference => r !== null);
    await Promise.all(dead.map((r) => r.delete()));
  } catch (e) {
    console.warn(`Push to ${uid} failed`, e);
  }
}

/** Queues an email through the Trigger Email extension (`mail` collection). */
async function sendMail(to: string, subject: string, text: string): Promise<void> {
  await db.collection("mail").add({to, message: {subject: `The Dossier: ${subject}`, text}});
}

/** Optional store / website link included in invitation emails. */
const APP_DOWNLOAD_URL = process.env.APP_DOWNLOAD_URL ?? "";
/** Cap on invitation emails per owner per day, so the server can't be used to spam. */
const MAX_INVITES_PER_DAY = 10;

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
  const windowMs = OBJECTION_HOURS > 0 ? OBJECTION_HOURS * 60 * 60 * 1000 : days * DAY_MS;
  const deadline = Timestamp.fromMillis(Date.now() + windowMs);
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
// Life Check — staged reminders, then ask confidants. Never releases data.
//
//   miss 1  owner: "Are you there?"
//   miss 2  owner: "Are you there?" + why we are asking
//   miss 3  owner: final notice — next time we ask your confidants
//   miss 4  confidants: "Is <owner> around?" (they are NOT told about any
//           Dossier for them). "Yes" resets the owner's clock; "No" leads
//           to the evidence + verification process.
// ---------------------------------------------------------------------------

/** Time until the next stage after a miss: 3 days, or the interval itself for short test intervals. */
function retryGapMs(lc: Record<string, unknown>): number {
  const mins = Number(lc.intervalMinutes) || 0;
  return mins > 0 && mins < 24 * 60 ? mins * 60 * 1000 : 3 * DAY_MS;
}

function describeInterval(lc: Record<string, unknown>): string {
  const mins = Number(lc.intervalMinutes) || Number(lc.intervalDays) * 24 * 60 || 30 * 24 * 60;
  const plural = (n: number, u: string) => `${n} ${u}${n === 1 ? "" : "s"}`;
  if (mins < 60) return plural(mins, "minute");
  if (mins < 24 * 60) return plural(Math.round(mins / 60), "hour");
  return plural(Math.round(mins / (24 * 60)), "day");
}

function publicBaseUrl(): string {
  const project = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT ?? "";
  return process.env.LIFE_CHECK_RESPONSE_URL || `https://${REGION}-${project}.cloudfunctions.net/lifeCheckResponse`;
}

export const lifeCheckSweep = onSchedule({schedule: LIFE_CHECK_SWEEP, timeZone: "Africa/Accra"}, async () => {
  const now = Timestamp.now();
  const due = await db
    .collection("users")
    .where("lifeCheck.enabled", "==", true)
    .where("lifeCheck.nextDue", "<=", now)
    .limit(500)
    .get();

  for (const doc of due.docs) {
    const ownerUid = doc.id;
    const lc = doc.data().lifeCheck ?? {};
    const paused = lc.pausedUntil as Timestamp | null | undefined;
    if (paused && paused.toMillis() > now.toMillis()) continue;

    const missed = (Number(lc.missed) || 0) + 1;
    const nextDue = Timestamp.fromMillis(now.toMillis() + retryGapMs(lc));
    console.log(`Life Check missed for ${ownerUid}: ${missed}`);
    await doc.ref.update({"lifeCheck.missed": missed, "lifeCheck.nextDue": nextDue});
    await audit(ownerUid, "lifecheck.missed");
    const lifeCheckAlert = {type: "lifeCheckOwner"};

    if (missed === 1) {
      await notify(ownerUid, "Are you there?",
        "Your Life Check is overdue. Open The Dossier and tap \"I'm OK\" to let us know you're well.", lifeCheckAlert);
    } else if (missed === 2) {
      await notify(ownerUid, "Are you there?",
        `We're asking because you set up a Life Check every ${describeInterval(lc)} and we haven't heard from you. ` +
          "It makes sure the people you trust are only contacted if something has really happened. " +
          "Open The Dossier and tap \"I'm OK\".", lifeCheckAlert);
    } else if (missed === 3) {
      await notify(ownerUid, "Final notice: are you there?",
        "If you don't let us know you're OK, we'll ask your trusted confidants whether you're around. " +
          "Nothing in your Dossier is shared with them. Open The Dossier and tap \"I'm OK\" to stop this.",
        lifeCheckAlert);
    } else if (missed === ASK_CONFIDANTS_AT) {
      const asked = await askConfidants(ownerUid);
      await notify(ownerUid, "We've asked your confidants to check on you",
        asked > 0 ?
          "You didn't respond to your Life Check, so we've asked your confidants whether you're around. " +
            "If you're well, open The Dossier and tap \"I'm OK\"." :
          "You didn't respond to your Life Check, but you have no confidants to ask. Add one under My Succession.",
        lifeCheckAlert);
    } else {
      await notify(ownerUid, "Are you there?",
        "Your Life Check is still overdue. Open The Dossier and tap \"I'm OK\".", lifeCheckAlert);
    }
  }
});

/** Creates a "is the owner around?" question for every confidant. Returns how many were asked. */
async function askConfidants(ownerUid: string): Promise<number> {
  const now = Date.now();
  const expiresAt = Timestamp.fromMillis(now + LIFE_CHECK_LINK_DAYS * DAY_MS);
  let asked = 0;

  // Confidants with the app: push + in-app question. The app shows the
  // owner's name, which only it can decrypt.
  const noms = await db.collection("nominations").where("ownerUid", "==", ownerUid).get();
  for (const n of noms.docs) {
    const granteeUid = n.data().granteeUid as string;
    const ref = db.collection("lifeChecks").doc(randomBytes(24).toString("hex"));
    await ref.set({ownerUid, granteeUid, status: "open", createdAt: FieldValue.serverTimestamp(), expiresAt});
    await notify(granteeUid, "Is someone you know OK?",
      "Someone who listed you as a trusted contact hasn't responded to us for a while. " +
        "Open The Dossier to let us know if they're around.", {type: "lifeCheckQuestion", id: ref.id});
    asked++;
  }

  // Invited confidants without the app: email with a one-time link.
  const invites = await db.collection("invites")
    .where("ownerUid", "==", ownerUid)
    .where("status", "==", "pending")
    .get();
  for (const inv of invites.docs) {
    const {email, emailHash, ownerName} = inv.data();
    const token = randomBytes(24).toString("hex");
    await db.collection("lifeChecks").doc(token).set({
      ownerUid, email, emailHash, ownerName: ownerName || "", status: "open", createdAt: FieldValue.serverTimestamp(), expiresAt,
    });
    const name = ownerName || "Someone you know";
    await sendMail(email, `Is ${name} OK?`,
      `Hello,\n\n${name} uses The Dossier, an app that helps people keep their important records organised ` +
        "and makes sure the right people are contacted if something happens to them. They listed you as " +
        "someone we can ask if we can't reach them.\n\n" +
        `We haven't heard from ${name} for a while. Could you let us know if they're around?\n\n` +
        `${publicBaseUrl()}?t=${token}\n\n` +
        "To protect you from phishing: this link only asks whether they're OK. We will never ask for passwords, " +
        "bank details or payment. If you're unsure about this email, don't click — instead install The Dossier " +
        "from the official App Store or Google Play and sign up with this email address; the question will be " +
        "waiting for you there, and you'll be able to keep track of future requests safely.\n\n" +
        "The Dossier team");
    asked++;
  }
  return asked;
}

/** Applies a confidant's answer. "alive" resets the owner's Life Check clock. */
async function applyLifeCheckAnswer(
  ref: FirebaseFirestore.DocumentReference, answer: "alive" | "not_alive", via: string,
): Promise<string> {
  const snap = await ref.get();
  const q = snap.data();
  if (!q) throw new HttpsError("not-found", "This question no longer exists.");
  if (q.status !== "open") throw new HttpsError("failed-precondition", "This question has already been answered.");
  if ((q.expiresAt as Timestamp).toMillis() < Date.now()) {
    await ref.update({status: "expired"});
    throw new HttpsError("deadline-exceeded", "This question has expired.");
  }
  const ownerUid = q.ownerUid as string;
  await ref.update({status: answer, answeredAt: FieldValue.serverTimestamp(), answeredVia: via});

  if (answer === "alive") {
    const owner = await db.doc(`users/${ownerUid}`).get();
    const lc = owner.data()?.lifeCheck ?? {};
    const now = Date.now();
    const mins = Number(lc.intervalMinutes) || (Number(lc.intervalDays) || 30) * 24 * 60;
    await owner.ref.update({
      "lifeCheck.lastCheckIn": Timestamp.fromMillis(now),
      "lifeCheck.nextDue": Timestamp.fromMillis(now + mins * 60 * 1000),
      "lifeCheck.missed": 0,
    });
    // Everyone else's question is no longer needed.
    const open = await db.collection("lifeChecks").where("ownerUid", "==", ownerUid).where("status", "==", "open").get();
    await Promise.all(open.docs.map((d) => d.ref.update({status: "resolved"})));
    await audit(ownerUid, "lifecheck.confirmedAlive");
    await notify(ownerUid, "A confidant confirmed you're OK",
      "One of your trusted confidants told us you're around, so your Life Check has been reset. " +
        "Next time, tap \"I'm OK\" in The Dossier.", {type: "lifeCheckOwner"});
  } else {
    await audit(ownerUid, "lifecheck.reportedNotAlive");
    await notify(ownerUid, "A confidant reported that you may not be well",
      "One of your confidants told us you may have passed away or be unable to respond. If you're well, open " +
        "The Dossier and tap \"I'm OK\". Nothing is released without verified evidence and a notice period.",
      {type: "lifeCheckOwner"});
  }
  return ownerUid;
}

/** Owner checked in themselves: questions to confidants are no longer needed. */
export const onOwnerCheckedIn = onDocumentUpdated("users/{uid}", async (event) => {
  const before = Number(event.data?.before.data()?.lifeCheck?.missed) || 0;
  const after = Number(event.data?.after.data()?.lifeCheck?.missed) || 0;
  if (before === 0 || after !== 0) return;
  const open = await db.collection("lifeChecks")
    .where("ownerUid", "==", event.params.uid)
    .where("status", "==", "open")
    .get();
  await Promise.all(open.docs.map((d) => d.ref.update({status: "resolved"})));
});

/** In-app answer from a confidant who has the app. */
export const answerLifeCheck = onCall(async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Sign in required.");
  const {id, answer} = (req.data ?? {}) as {id?: unknown; answer?: unknown};
  if (typeof id !== "string" || !/^[0-9a-f]{48}$/.test(id)) throw new HttpsError("invalid-argument", "Bad id.");
  if (answer !== "alive" && answer !== "not_alive") throw new HttpsError("invalid-argument", "Bad answer.");
  const ref = db.collection("lifeChecks").doc(id);
  const q = (await ref.get()).data();
  if (!q || q.granteeUid !== req.auth.uid) throw new HttpsError("permission-denied", "Not your question.");
  await applyLifeCheckAnswer(ref, answer, "app");
  return {ok: true};
});

const esc = (v: string) => v.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

function page(title: string, body: string): string {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex">
<title>${esc(title)} · The Dossier</title>
<style>
body{margin:0;font-family:-apple-system,system-ui,Segoe UI,Roboto,sans-serif;background:#0d0d0f;color:#f5f3ee;
display:flex;justify-content:center;padding:32px 16px;line-height:1.5}
main{max-width:520px;width:100%}h1{font-size:28px;margin:8px 0 12px}
.brand{color:#f2b33d;font-weight:700;letter-spacing:.04em}
.card{background:#1a1a1e;border:1px solid #2c2c31;border-radius:20px;padding:20px;margin:18px 0}
button{width:100%;padding:16px;border-radius:999px;border:0;font-size:16px;font-weight:700;margin-top:10px;cursor:pointer}
.yes{background:#f2b33d;color:#0d0d0f}.no{background:transparent;color:#f5f3ee;border:1px solid #444}
small{color:#a9a6a0}
</style></head><body><main><div class="brand">THE DOSSIER</div>${body}</main></body></html>`;
}

const SAFETY = `<div class="card"><b>Staying safe from phishing</b><br><small>We will never ask for passwords,
bank details or payment. If anything about this feels wrong, close this page, install <b>The Dossier</b> from the
official App Store or Google Play and sign up with the email address this message was sent to. You'll find the
same question there and can keep track of future requests safely.</small></div>
<div class="card"><b>What is The Dossier?</b><br><small>An end-to-end encrypted app where people keep their important
records — family details, accounts, property, wishes — and choose who should be contacted if something happens to
them. It regularly checks in with them; when they don't respond, we ask the people they trust.</small></div>`;

/**
 * Email link for confidants without the app. GET only shows the question
 * (email scanners open links automatically); the answer is a POST.
 */
export const lifeCheckResponse = onRequest(async (req, res) => {
  res.set("Cache-Control", "no-store");
  res.set("X-Frame-Options", "DENY");
  const token = String(req.query.t ?? req.body?.t ?? "");
  if (!/^[0-9a-f]{48}$/.test(token)) {
    res.status(404).send(page("Link not valid", "<h1>This link isn't valid</h1>" + SAFETY));
    return;
  }
  const ref = db.collection("lifeChecks").doc(token);
  const q = (await ref.get()).data();
  if (!q || !q.email) {
    res.status(404).send(page("Link not valid", "<h1>This link isn't valid</h1>" + SAFETY));
    return;
  }
  const name = esc(String(q.ownerName || "the person who listed you"));

  if (req.method === "POST") {
    const answer = String(req.body?.answer ?? "");
    if (answer !== "alive" && answer !== "not_alive") {
      res.status(400).send(page("Something went wrong", "<h1>Please choose an answer</h1>"));
      return;
    }
    try {
      await applyLifeCheckAnswer(ref, answer, "email");
    } catch (e) {
      const msg = e instanceof HttpsError ? e.message : "Something went wrong. Please try again later.";
      res.status(400).send(page("Could not record answer", `<h1>${esc(msg)}</h1>` + SAFETY));
      return;
    }
    if (answer === "alive") {
      res.send(page("Thank you", `<h1>Thank you</h1><p>We've let ${name} know, and we won't contact you again
about this check.</p>` + SAFETY));
    } else {
      res.send(page("We're sorry", `<h1>We're very sorry</h1><p>Thank you for letting us know. To protect ${name},
nothing happens until our verification team has reviewed official evidence, such as a death certificate or a
medical report.</p><div class="card"><b>Next step</b><br>Install <b>The Dossier</b> from the App Store or Google
Play and sign up with <b>${esc(String(q.email))}</b>. You'll then be able to upload the evidence securely and follow
the verification.</div>` + SAFETY));
    }
    return;
  }

  if (q.status !== "open" || (q.expiresAt as Timestamp).toMillis() < Date.now()) {
    res.send(page("Already answered", "<h1>This question has already been answered or has expired</h1>" +
      "<p>Thank you. There's nothing more you need to do.</p>" + SAFETY));
    return;
  }
  res.send(page(`Is ${name} OK?`, `<h1>Is ${name} OK?</h1>
<p>${name} listed you as someone we can ask if we can't reach them. We haven't heard from them for a while.</p>
<form method="post"><input type="hidden" name="t" value="${token}">
<button class="yes" name="answer" value="alive">Yes, they're around</button>
<button class="no" name="answer" value="not_alive">No, they have passed away or can't respond</button>
</form>` + SAFETY));
});

// ---------------------------------------------------------------------------
// Confidant invitations — for people who don't have The Dossier yet
// ---------------------------------------------------------------------------

export const onInviteCreated = onDocumentCreated("invites/{id}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const inv = snap.data();
  const since = Timestamp.fromMillis(Date.now() - DAY_MS);
  const recent = await db.collection("invites")
    .where("ownerUid", "==", inv.ownerUid)
    .where("createdAt", ">=", since)
    .count()
    .get();
  if (recent.data().count > MAX_INVITES_PER_DAY) {
    await snap.ref.update({status: "rate-limited"});
    return;
  }
  const owner = String(inv.ownerName || "Someone").slice(0, 80);
  const invitee = String(inv.inviteeName || "").slice(0, 80);
  await sendMail(
    inv.email,
    `${owner} named you as a trusted confidant`,
    `Hello${invitee ? " " + invitee : ""},\n\n` +
      `${owner} has named you as a trusted confidant in The Dossier, an end-to-end encrypted app for ` +
      "organising important records and passing them on to the right people.\n\n" +
      "To accept, install The Dossier and create an account with this email address" +
      (APP_DOWNLOAD_URL ? `:\n${APP_DOWNLOAD_URL}\n\n` : ".\n\n") +
      `${owner} will then be able to finish adding you. You won't be able to see anything now: ` +
      "information is only released to you if a death or incapacity is verified.\n\n" +
      "If you weren't expecting this, you can ignore this email.",
  );
  await snap.ref.update({sentAt: FieldValue.serverTimestamp()});
  await audit(inv.ownerUid, "invite.sent");
});

/** When an invited confidant creates an account, tell the owner to finish sealing keys to them. */
export const onDirectoryEntryCreated = onDocumentCreated("directory/{hash}", async (event) => {
  const invites = await db.collection("invites")
    .where("emailHash", "==", event.params.hash)
    .where("status", "==", "pending")
    .get();
  for (const inv of invites.docs) {
    const {ownerUid, inviteeName} = inv.data();
    await inv.ref.update({status: "joined", joinedAt: FieldValue.serverTimestamp()});
    // Any open "is the owner OK?" question emailed to them now also appears in the app.
    const questions = await db.collection("lifeChecks")
      .where("emailHash", "==", event.params.hash)
      .where("status", "==", "open")
      .get();
    const uid = event.data?.data()?.uid as string | undefined;
    for (const q of questions.docs) {
      if (uid) await q.ref.update({granteeUid: uid});
    }
    await notify(
      ownerUid,
      `${inviteeName || "Your confidant"} has joined The Dossier`,
      "Open My Succession, tap their name and save to finish sealing their access.",
    );
  }
});

// ---------------------------------------------------------------------------
// Account deletion — purge everything the client could not delete itself.
// ---------------------------------------------------------------------------

export const onUserDeleted = functionsV1.region(REGION).auth.user().onDelete(async (user) => {
  const uid = user.uid;
  await db.recursiveDelete(db.doc(`users/${uid}`));
  const batch = db.batch();
  const [dir, nomsOwner, nomsGrantee, grantsAsGrantee, invites, lifeChecks] = await Promise.all([
    db.collection("directory").where("uid", "==", uid).get(),
    db.collection("nominations").where("ownerUid", "==", uid).get(),
    db.collection("nominations").where("granteeUid", "==", uid).get(),
    db.collectionGroup("grants").where("granteeUid", "==", uid).get(),
    db.collection("invites").where("ownerUid", "==", uid).get(),
    db.collection("lifeChecks").where("ownerUid", "==", uid).get(),
  ]);
  [...dir.docs, ...nomsOwner.docs, ...nomsGrantee.docs, ...grantsAsGrantee.docs, ...invites.docs,
    ...lifeChecks.docs].forEach((d) => batch.delete(d.ref));
  await batch.commit();
  await getStorage().bucket().deleteFiles({prefix: `users/${uid}/`});
});
