import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

const rules = readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8');
const testEnvironment = await initializeTestEnvironment({
  projectId: 'demo-daisth-rules',
  firestore: {
    host: '127.0.0.1',
    port: 8080,
    rules,
  },
});

try {
  const owner = testEnvironment.authenticatedContext('qa-user-a').firestore();
  const otherUser = testEnvironment.authenticatedContext('qa-user-b').firestore();
  const unauthenticated = testEnvironment.unauthenticatedContext().firestore();

  await testEnvironment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await firestore.doc('users/qa-user-a').set({ marker: 'owner' });
    await firestore.doc('users/qa-user-a/routineRecords/record-a').set({
      marker: 'owner-record',
    });
    await firestore.doc('users/qa-user-b').set({ marker: 'other-user' });
    await firestore.doc('users/qa-user-b/routineRecords/record-b').set({
      marker: 'other-record',
    });
  });

  await assertFails(unauthenticated.doc('users/qa-user-a').get());
  await assertFails(
    unauthenticated.doc('users/qa-user-a/notes/unauthenticated').set({ text: 'x' }),
  );

  await assertSucceeds(owner.doc('users/qa-user-a').get());
  await assertSucceeds(owner.doc('users/qa-user-a/routineRecords/record-a').get());
  await assertSucceeds(
    owner.doc('users/qa-user-a/notes/owner-write').set({ text: 'owner-write' }),
  );
  await assertSucceeds(
    owner.doc('users/qa-user-a/routineRecords/record-a').update({
      isDeleted: true,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    }),
  );
  await assertSucceeds(owner.doc('users/qa-user-a/notes/owner-write').delete());

  await assertFails(otherUser.doc('users/qa-user-a').get());
  await assertFails(otherUser.doc('users/qa-user-a/routineRecords/record-a').get());
  await assertFails(
    otherUser.doc('users/qa-user-a/notes/cross-user-write').set({ text: 'x' }),
  );
  await assertFails(otherUser.doc('users/qa-user-a').delete());
  await assertFails(
    otherUser.doc('users/qa-user-a/routineRecords/record-a').update({
      isDeleted: true,
    }),
  );

  console.log(
    'PASS: unauthenticated access denied; owners can read/write/delete their data and create tombstones; cross-user access denied.',
  );
} finally {
  await testEnvironment.cleanup();
}
