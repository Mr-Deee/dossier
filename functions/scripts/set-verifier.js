/**
 * Grants or removes the `verifier` role (verification / legal partner).
 *
 *   GOOGLE_APPLICATION_CREDENTIALS=service-account.json \
 *     node scripts/set-verifier.js someone@lawfirm.com.gh [--remove]
 *
 * Verifiers can review access requests and evidence. They can never decrypt
 * any user's records — they hold no keys.
 */
const {initializeApp, applicationDefault} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");

async function main() {
  const [email, flag] = process.argv.slice(2);
  if (!email) throw new Error("Usage: node scripts/set-verifier.js <email> [--remove]");
  initializeApp({credential: applicationDefault()});
  const user = await getAuth().getUserByEmail(email);
  const claims = {...(user.customClaims || {})};
  if (flag === "--remove") delete claims.verifier;
  else claims.verifier = true;
  await getAuth().setCustomUserClaims(user.uid, claims);
  console.log(`${flag === "--remove" ? "Removed" : "Granted"} verifier role for ${email} (${user.uid}).`);
}
main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
