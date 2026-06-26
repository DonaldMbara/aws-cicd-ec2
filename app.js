const express = require('express');
const app = express();
const PORT = 3000;

app.get('/health', (req, res) => {
  res.status(500).json({ status: 'error' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});