const express = require('express');
const app = express();
const PORT = 3000;

app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: '1.0' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});