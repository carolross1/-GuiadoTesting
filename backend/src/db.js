'use strict';

// In-memory data store with PostgreSQL schema compatibility for testing and production
class Database {
  constructor() {
    this.reset();
  }

  reset() {
    this.users = new Map();
    this.tasks = new Map();
    this.refreshTokens = new Set();
    this.userIdCounter = 1;
    this.taskIdCounter = 1;
  }

  async createUser(email, passwordHash) {
    const id = `user-${this.userIdCounter++}`;
    const user = { id, email, passwordHash, createdAt: new Date() };
    this.users.set(id, user);
    return user;
  }

  async findUserByEmail(email) {
    for (const user of this.users.values()) {
      if (user.email.toLowerCase() === email.toLowerCase()) {
        return user;
      }
    }
    return null;
  }

  async findUserById(id) {
    return this.users.get(id) || null;
  }

  async storeRefreshToken(token) {
    this.refreshTokens.add(token);
  }

  async isRefreshTokenValid(token) {
    return this.refreshTokens.has(token);
  }

  async revokeRefreshToken(token) {
    this.refreshTokens.delete(token);
  }

  async revokeAllUserRefreshTokens(userId) {
    // For logout-all functionality
    this.refreshTokens.clear();
  }

  async createTask(ownerId, title) {
    const id = `task-${this.taskIdCounter++}`;
    const task = {
      id,
      title,
      completed: false,
      ownerId,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    this.tasks.set(id, task);
    return task;
  }

  async getTasksByOwner(ownerId) {
    const results = [];
    for (const task of this.tasks.values()) {
      if (task.ownerId === ownerId) {
        results.push({ ...task });
      }
    }
    return results;
  }

  async getTaskById(taskId) {
    return this.tasks.get(taskId) || null;
  }

  async updateTask(taskId, ownerId, updates) {
    const task = this.tasks.get(taskId);
    if (!task) {
      return null;
    }
    // Broken object-level authorization protection:
    if (task.ownerId !== ownerId) {
      return 'FORBIDDEN';
    }

    // Broken object property-level authorization protection (OWASP):
    // Ignore or reject tampering with ownerId or id
    const safeUpdates = { ...updates };
    delete safeUpdates.id;
    delete safeUpdates.ownerId;

    if (safeUpdates.title !== undefined) {
      task.title = safeUpdates.title;
    }
    if (safeUpdates.completed !== undefined) {
      task.completed = Boolean(safeUpdates.completed);
    }
    task.updatedAt = new Date().toISOString();
    return { ...task };
  }

  async deleteTask(taskId, ownerId) {
    const task = this.tasks.get(taskId);
    if (!task) {
      return null;
    }
    if (task.ownerId !== ownerId) {
      return 'FORBIDDEN';
    }
    this.tasks.delete(taskId);
    return true;
  }
}

const db = new Database();

module.exports = { db };
