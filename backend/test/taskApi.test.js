'use strict';

const request = require('supertest');
const { app } = require('../src/app');
const { db } = require('../src/db');
const { generateAccessToken } = require('../src/auth');

// Isolated test helper functions (as described on Page 10 of guide)
let userIndex = 1;
async function createTestUserAndGetToken() {
  const user = await db.createUser(`user${userIndex++}@example.test`, 'hashed_secret_pw');
  return generateAccessToken(user);
}

async function createTask(token, title) {
  const response = await request(app)
    .post('/api/v1/tasks')
    .set('Authorization', `Bearer ${token}`)
    .send({ title });
  return response.body.id;
}

beforeEach(() => {
  db.reset();
  userIndex = 1;
});

describe('Task API & Security Tests (Sections 6 & 9)', () => {
  // Document Section 6: Base tests
  test('rejects task creation without authentication', async () => {
    const response = await request(app)
      .post('/api/v1/tasks')
      .send({ title: 'Plan tests' });
    expect(response.status).toBe(401);
  });

  test('rejects an empty title', async () => {
    const token = await createTestUserAndGetToken();
    const response = await request(app)
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: ' ' });
    expect(response.status).toBe(400);
  });

  test('does not let one user read another user task', async () => {
    const owner = await createTestUserAndGetToken();
    const stranger = await createTestUserAndGetToken();
    const taskId = await createTask(owner, 'Private task');

    const response = await request(app)
      .get(`/api/v1/tasks/${taskId}`)
      .set('Authorization', `Bearer ${stranger}`);
    expect([403, 404]).toContain(response.status);
  });

  // Practice Exercise (Section 6, Page 10):
  // 1. Invalid task ID test
  test('rejects request with an invalid or non-existent task ID', async () => {
    const token = await createTestUserAndGetToken();
    const response = await request(app)
      .get('/api/v1/tasks/non-existent-task-id-9999')
      .set('Authorization', `Bearer ${token}`);
    expect(response.status).toBe(404);
  });

  // 2. Missing title test
  test('rejects task creation when title is missing from payload', async () => {
    const token = await createTestUserAndGetToken();
    const response = await request(app)
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(response.status).toBe(400);
  });

  // 3. User attempting to update another user\'s task
  test('does not let a user update another user\'s task', async () => {
    const owner = await createTestUserAndGetToken();
    const attacker = await createTestUserAndGetToken();
    const taskId = await createTask(owner, 'Owner original task');

    const response = await request(app)
      .put(`/api/v1/tasks/${taskId}`)
      .set('Authorization', `Bearer ${attacker}`)
      .send({ title: 'Hacked task' });

    expect([403, 404]).toContain(response.status);

    // Verify original task remains untouched
    const verifyResp = await request(app)
      .get(`/api/v1/tasks/${taskId}`)
      .set('Authorization', `Bearer ${owner}`);
    expect(verifyResp.body.title).toBe('Owner original task');
  });

  // Practice Exercise (Section 9, Page 13 - OWASP Broken Object Property Level Auth):
  // "In the test environment, try to update a task with an ownerId field. Verify that the API ignores or rejects it and retains server-derived ownership."
  test('ignores client-supplied ownerId and preserves original ownership', async () => {
    const owner = await createTestUserAndGetToken();
    const otherUser = await createTestUserAndGetToken();
    const taskId = await createTask(owner, 'Ownership protection test');

    const response = await request(app)
      .put(`/api/v1/tasks/${taskId}`)
      .set('Authorization', `Bearer ${owner}`)
      .send({
        title: 'Updated title',
        ownerId: otherUser // Attacker attempts to transfer task to another user
      });

    expect(response.status).toBe(200);

    // Task still owned by original user, not otherUser
    const checkOriginalOwner = await request(app)
      .get(`/api/v1/tasks/${taskId}`)
      .set('Authorization', `Bearer ${owner}`);
    expect(checkOriginalOwner.status).toBe(200);
    expect(checkOriginalOwner.body.ownerId).not.toBe(otherUser);
  });

  // Negative behavior tests (Section 9, Page 12):
  test('safely handles injection-like SQL strings as standard plain text', async () => {
    const token = await createTestUserAndGetToken();
    const sqlInjectionTitle = "Test ' OR '1'='1";
    const response = await request(app)
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: sqlInjectionTitle });

    expect(response.status).toBe(201);
    expect(response.body.title).toBe(sqlInjectionTitle);
  });

  test('safely stores HTML/XSS markup without executing it', async () => {
    const token = await createTestUserAndGetToken();
    const xssPayload = '<script>alert(1)</script>';
    const response = await request(app)
      .post('/api/v1/tasks')
      .set('Authorization', `Bearer ${token}`)
      .send({ title: xssPayload });

    expect(response.status).toBe(201);
    expect(response.body.title).toBe(xssPayload);
  });

  // Health endpoint test for k6 (Section 10)
  test('GET /health returns 200 with status ok', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ok');
  });
});
