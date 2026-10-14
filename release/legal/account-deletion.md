# Daisth — Account Deletion

**Status:** draf konten untuk halaman web publik. Berkas repository ini bukan halaman web dan tidak menyediakan saluran permintaan.  
**PUBLIC ACCOUNT DELETION URL: USER INPUT REQUIRED**  
**Monitored support/deletion contact or web form: USER INPUT REQUIRED**

## Delete your Daisth account in the app

In Daisth, open **Settings → Account / Data & Privacy → Delete Account**. Confirm the request and reauthenticate with the provider used for the account. Daisth deletes the Firebase Authentication account and the Daisth cloud-sync data associated with its UID. For Sign in with Apple accounts, Apple authorization revocation is part of the implemented deletion flow once Apple production configuration is available.

If reauthentication, cloud deletion, provider revocation, or Firebase account deletion fails, the app reports that it could not complete the deletion; it does not silently claim success. Cloud data may already have been purged before a later provider/account deletion step fails. Retry the in-app deletion or contact the monitored support route below for assistance.

## What remains on your device

Account deletion intentionally leaves the app's local SQLite data on the physical device. This includes locally stored routines, history, and Reflection. The app can continue in local-only mode. Remove local app data separately through the app/device controls if desired. Daisth does not claim that deleting the account deletes local device data.

## Request deletion when the app is not installed

**USER INPUT REQUIRED:** publish this page at a stable HTTPS URL and add a real monitored mechanism here (for example, a secure form or monitored support contact). The mechanism must let a person identify their Daisth account and submit a request for deletion of the account and associated cloud data without the app installed. Do not publish this draft or represent it as a working request pathway until that mechanism exists. Do not ask people to send passwords or authentication tokens.

**Deletion request mechanism:** USER INPUT REQUIRED — public form/contact and how requests are verified and completed.  
**Developer identity:** USER INPUT REQUIRED — legal/developer name.  
**Privacy/support contact:** USER INPUT REQUIRED — monitored contact.
