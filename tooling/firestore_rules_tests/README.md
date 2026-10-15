# Firestore rules tests

This isolated Node test harness exercises `firestore.rules` against the local
Firestore Emulator with a demo project ID. It never connects to or deploys to
the production Firebase project.

Requirements: Node.js 18+, npm, Firebase CLI, and Java.

From this directory:

```sh
npm install
npm test
```
