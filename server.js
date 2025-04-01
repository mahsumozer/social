const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const http = require('http');
const socketIo = require('socket.io');

// Route'ları import et
const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json());

// Route'ları kullan
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);

// MongoDB bağlantısı
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/tinder-clone', {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log('MongoDB bağlantısı başarılı');
}).catch((error) => {
  console.error('MongoDB bağlantı hatası:', error);
});

// Socket.io olayları
io.on('connection', (socket) => {
  console.log('Yeni bir kullanıcı bağlandı');

  socket.on('disconnect', () => {
    console.log('Kullanıcı ayrıldı');
  });

  // Eşleşme bildirimi
  socket.on('match', (data) => {
    io.emit('newMatch', data);
  });
});

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`Sunucu ${PORT} portunda çalışıyor`);
}); 