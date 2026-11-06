'use strict';

const { app } = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Task Manager API running at http://localhost:${PORT}`);
  console.log(`Health endpoint: http://localhost:${PORT}/health`);
});
