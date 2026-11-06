'use strict';

const express = require('express');
const cors = require('cors');
const { validateTitle } = require('./tasks/validation');
const { db } = require('./db');
const {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
  authenticateToken,
  hashPassword,
  comparePassword
} = require('./auth');

const app = express();

app.use(cors());
app.use(express.json({ limit: '10kb' })); // Bound body size (OWASP unrestricted resource consumption check)

// Health check endpoint for k6 load testing (Document section 10)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Authentication endpoints
app.post('/api/v1/auth/register', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password || typeof email !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }
    const existing = await db.findUserByEmail(email);
    if (existing) {
      return res.status(409).json({ error: 'User already exists' });
    }

    const passwordHash = await hashPassword(password);
    const user = await db.createUser(email, passwordHash);
    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);
    await db.storeRefreshToken(refreshToken);

    res.status(201).json({
      user: { id: user.id, email: user.email },
      accessToken,
      refreshToken
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    const user = await db.findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const match = await comparePassword(password, user.passwordHash);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);
    await db.storeRefreshToken(refreshToken);

    res.status(200).json({
      user: { id: user.id, email: user.email },
      accessToken,
      refreshToken
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/v1/auth/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ error: 'Refresh token is required' });
  }

  const isValid = await db.isRefreshTokenValid(refreshToken);
  if (!isValid) {
    return res.status(401).json({ error: 'Invalid or revoked refresh token' });
  }

  try {
    const payload = verifyRefreshToken(refreshToken);
    const user = await db.findUserById(payload.sub);
    if (!user) {
      return res.status(401).json({ error: 'User no longer exists' });
    }

    // Refresh token rotation (OWASP)
    await db.revokeRefreshToken(refreshToken);
    const newAccessToken = generateAccessToken(user);
    const newRefreshToken = generateRefreshToken(user);
    await db.storeRefreshToken(newRefreshToken);

    res.status(200).json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    });
  } catch (err) {
    await db.revokeRefreshToken(refreshToken);
    return res.status(401).json({ error: 'Expired or invalid refresh token' });
  }
});

app.post('/api/v1/auth/logout', async (req, res) => {
  const { refreshToken } = req.body;
  if (refreshToken) {
    await db.revokeRefreshToken(refreshToken);
  }
  res.status(200).json({ message: 'Logged out successfully' });
});

// Task endpoints (Protected by authenticateToken)
app.post('/api/v1/tasks', authenticateToken, async (req, res) => {
  try {
    const { title } = req.body;
    let validatedTitle;
    try {
      validatedTitle = validateTitle(title);
    } catch (valErr) {
      return res.status(400).json({ error: valErr.message });
    }

    const task = await db.createTask(req.user.id, validatedTitle);
    res.status(201).json(task);
  } catch (err) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/v1/tasks', authenticateToken, async (req, res) => {
  const tasks = await db.getTasksByOwner(req.user.id);
  res.status(200).json(tasks);
});

app.get('/api/v1/tasks/:id', authenticateToken, async (req, res) => {
  const task = await db.getTaskById(req.params.id);
  if (!task || task.ownerId !== req.user.id) {
    // Return 404 to not disclose existence of another user's task
    return res.status(404).json({ error: 'Task not found' });
  }
  res.status(200).json(task);
});

app.put('/api/v1/tasks/:id', authenticateToken, async (req, res) => {
  const existing = await db.getTaskById(req.params.id);
  if (!existing || existing.ownerId !== req.user.id) {
    return res.status(404).json({ error: 'Task not found' });
  }

  const updates = {};
  if (req.body.title !== undefined) {
    try {
      updates.title = validateTitle(req.body.title);
    } catch (valErr) {
      return res.status(400).json({ error: valErr.message });
    }
  }

  if (req.body.completed !== undefined) {
    updates.completed = Boolean(req.body.completed);
  }

  // Security check: Ignore or prevent setting ownerId from client input (OWASP property-level auth)
  const updated = await db.updateTask(req.params.id, req.user.id, updates);
  res.status(200).json(updated);
});

app.delete('/api/v1/tasks/:id', authenticateToken, async (req, res) => {
  const result = await db.deleteTask(req.params.id, req.user.id);
  if (result === null || result === 'FORBIDDEN') {
    return res.status(404).json({ error: 'Task not found' });
  }
  res.status(200).json({ message: 'Task deleted successfully' });
});

module.exports = { app };
