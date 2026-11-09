const fs = require('fs');
const path = require('path');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  serverTimestamp,
  Timestamp,
} = require('firebase/firestore');

const PROJECT_ID = 'homesureai-security-tests';

const PROPERTY_ID = 'test-property-001';

const requestPath = (uid) =>
  `properties/${PROPERTY_ID}/community/main/membership_requests/${uid}`;

const memberPath = (uid) =>
  `properties/${PROPERTY_ID}/community/main/members/${uid}`;

let testEnv;

describe('HomeSureAI membership Firestore security rules', function () {
  this.timeout(15000);

  before(async function () {
    const rulesPath = path.resolve(__dirname, '../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { rules },
    });
  });

  beforeEach(async function () {
    await testEnv.clearFirestore();
  });

  after(async function () {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  it('allows a resident to submit their own pending request', async function () {
    const db = testEnv.authenticatedContext('resident-a').firestore();

    await assertSucceeds(
      setDoc(doc(db, requestPath('resident-a')), {
        userId: 'resident-a',
        propertyId: PROPERTY_ID,
        relationship: 'owner',
        status: 'pending',
        requestedAt: serverTimestamp(),
        displayName: 'Resident A',
        message: null,
      })
    );
  });

  it('allows a resident to read their own membership request', async function () {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, requestPath('resident-a')), {
        userId: 'resident-a',
        propertyId: PROPERTY_ID,
        relationship: 'owner',
        status: 'pending',
        requestedAt: Timestamp.now(),
        displayName: 'Resident A',
        message: null,
      });
    });

    const db = testEnv.authenticatedContext('resident-a').firestore();

    await assertSucceeds(
      getDoc(doc(db, requestPath('resident-a')))
    );
  });

  it('denies a resident access to another resident request', async function () {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, requestPath('resident-b')), {
        userId: 'resident-b',
        propertyId: PROPERTY_ID,
        relationship: 'tenant',
        status: 'pending',
        requestedAt: Timestamp.now(),
        displayName: 'Resident B',
        message: null,
      });
    });

    const db = testEnv.authenticatedContext('resident-a').firestore();

    await assertFails(
      getDoc(doc(db, requestPath('resident-b')))
    );
  });

  it('denies a resident attempting to approve their own request', async function () {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, requestPath('resident-a')), {
        userId: 'resident-a',
        propertyId: PROPERTY_ID,
        relationship: 'owner',
        status: 'pending',
        requestedAt: Timestamp.now(),
        displayName: 'Resident A',
        message: null,
      });
    });

    const db = testEnv.authenticatedContext('resident-a').firestore();

    await assertFails(
      updateDoc(doc(db, requestPath('resident-a')), {
        status: 'approved',
      })
    );
  });

  it('denies a resident creating their own approved membership', async function () {
    const db = testEnv.authenticatedContext('resident-a').firestore();

    await assertFails(
      setDoc(doc(db, memberPath('resident-a')), {
        userId: 'resident-a',
        propertyId: PROPERTY_ID,
        status: 'approved',
        relationship: 'owner',
        role: 'member',
        requestedAt: serverTimestamp(),
      })
    );
  });

  it('denies a resident granting themselves an administrator role', async function () {
    const db = testEnv.authenticatedContext('resident-a').firestore();

    await assertFails(
      setDoc(doc(db, memberPath('resident-a')), {
        userId: 'resident-a',
        propertyId: PROPERTY_ID,
        status: 'approved',
        relationship: 'owner',
        role: 'admin',
        requestedAt: serverTimestamp(),
      })
    );
  });

  it('denies an existing member changing their role to administrator', async function () {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      await setDoc(doc(db, memberPath('resident-a')), {
        userId: 'resident-a',
        propertyId: PROPERTY_ID,
        status: 'approved',
        relationship: 'owner',
        role: 'member',
        requestedAt: Timestamp.now(),
      });
    });

    const db = testEnv.authenticatedContext('resident-a').firestore();

    await assertFails(
      updateDoc(doc(db, memberPath('resident-a')), {
        role: 'admin',
      })
    );
  });
});
