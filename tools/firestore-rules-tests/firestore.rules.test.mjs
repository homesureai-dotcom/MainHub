import fs from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  where,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
} from 'firebase/firestore';

const PROJECT_ID = 'homesureai-51893';
const RULES_PATH = '../../firestore.rules';

let testEnv;

const validSubmission = (uid, status = 'pending_review') => ({
  name: 'Pilot Apartment',
  builder: 'Example Builder',
  locality: 'Whitefield',
  city: 'Bengaluru',
  reraNumber: '',
  submittedBy: uid,
  status,
  createdAt: serverTimestamp(),
});

async function runTest(name, callback) {
  try {
    await callback();
    console.log(`PASS: ${name}`);
  } catch (error) {
    console.error(`FAIL: ${name}`);
    console.error(error);
    process.exitCode = 1;
  }
}

const validSession = {
  assessmentId: 'sessionA',
  propertyId: 'propertyA',
  submissionId: null,
  status: 'inProgress',
  startedAt: new Date(),
  lastUpdatedAt: new Date(),
  currentQuestionId: 'question1',
  answers: [],
};

try {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8180,
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
    },
  });

  await testEnv.clearFirestore();

  await runTest('Assessment session owner can create and read their session', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const ref = doc(db, 'users/userA/assessment_sessions/sessionA');
    await assertSucceeds(setDoc(ref, validSession));
    await assertSucceeds(getDoc(ref));
  });

  await runTest('Another user cannot read an assessment session', async () => {
    const db = testEnv.authenticatedContext('userB').firestore();
    await assertFails(
      getDoc(doc(db, 'users/userA/assessment_sessions/sessionA')),
    );
  });

  await runTest('Assessment session owner can update their session', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      updateDoc(
        doc(db, 'users/userA/assessment_sessions/sessionA'),
        { currentQuestionId: 'question2' },
      ),
    );
  });

  await runTest('Assessment session cannot be deleted through the app', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      deleteDoc(doc(db, 'users/userA/assessment_sessions/sessionA')),
    );
  });

  await runTest('Unauthenticated user cannot create an assessment session', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      setDoc(
        doc(db, 'users/anonymous/assessment_sessions/sessionX'),
        { ...validSession, assessmentId: 'sessionX' },
      ),
    );
  });

  await runTest('Signed-in user can submit a pending property', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      setDoc(
        doc(db, 'property_submissions', 'submissionA'),
        validSubmission('userA'),
      ),
    );
  });

  await runTest('User cannot submit for another user', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      setDoc(
        doc(db, 'property_submissions', 'wrongOwner'),
        validSubmission('userB'),
      ),
    );
  });

  await runTest('User cannot create an already approved submission', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      setDoc(
        doc(db, 'property_submissions', 'preApproved'),
        validSubmission('userA', 'approved'),
      ),
    );
  });

  await runTest('Unauthenticated user cannot submit a property', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      setDoc(
        doc(db, 'property_submissions', 'anonymous'),
        validSubmission('anonymous'),
      ),
    );
  });

  await runTest('Owner can read their own submission', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertSucceeds(
      getDoc(doc(db, 'property_submissions', 'submissionA')),
    );
  });

  await runTest('Another user cannot read the submission', async () => {
    const db = testEnv.authenticatedContext('userB').firestore();
    await assertFails(
      getDoc(doc(db, 'property_submissions', 'submissionA')),
    );
  });

  await runTest('Owner can query only their own submissions', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    const ownRequests = query(
      collection(db, 'property_submissions'),
      where('submittedBy', '==', 'userA'),
    );
    await assertSucceeds(getDocs(ownRequests));
  });

  await runTest('App user cannot approve a submission', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      updateDoc(
        doc(db, 'property_submissions', 'submissionA'),
        { status: 'approved' },
      ),
    );
  });

  await runTest('App user cannot delete a submission', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      deleteDoc(doc(db, 'property_submissions', 'submissionA')),
    );
  });

  await runTest('Owner cannot add unapproved extra fields', async () => {
    const db = testEnv.authenticatedContext('userA').firestore();
    await assertFails(
      setDoc(
        doc(db, 'property_submissions', 'extraField'),
        {
          ...validSubmission('userA'),
          approvedBy: 'userA',
        },
      ),
    );
  });
} catch (error) {
  console.error('Could not initialize or run the rules tests.');
  console.error(error);
  process.exitCode = 1;
} finally {
  if (testEnv) {
    await testEnv.cleanup();
  }
}
