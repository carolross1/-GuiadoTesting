'use strict';

const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const ACCESS_SECRET = process.env.ACCESS_TOKEN_SECRET || 'task-manager-test-access-secret-key-1234';
const REFRESH_SECRET = process.env.REFRESH_TOKEN_SECRET || 'task-manager-test-refresh-secret-key-5678';

function generateAccessToken(user) {
  return jwt.sign(
    { sub: user.id, email: user.email },
    ACCESS_SECRET,
    { expiresIn: '15m' }
  );
}

function generateRefreshToken(user) {
  return jwt.sign(
    { sub: user.id, email: user.email },
    REFRESH_SECRET,
    { expiresIn: '7d' }
  );
}

function verifyAccessToken(token) {
  return jwt.verify(token, ACCESS_SECRET);
}

function verifyRefreshToken(token) {
  return jwt.verify(token, REFRESH_SECRET);
}

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({ error: 'Malformed token' });
  }

  const token = parts[1];
  try {
    const payload = verifyAccessToken(token);
    req.user = { id: payload.sub, email: payload.email };
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  authenticateToken,
  hashPassword: (pw) => bcrypt.hash(pw, 10),
  comparePassword: (pw, hash) => bcrypt.compare(pw, hash)
};
