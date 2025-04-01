const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');

// Profil bilgilerini getirme
router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

// Profil güncelleme
router.put('/me', auth, async (req, res) => {
  try {
    const { name, age, gender, bio } = req.body;
    const user = await User.findById(req.user.userId);

    if (name) user.name = name;
    if (age) user.age = age;
    if (gender) user.gender = gender;
    if (bio) user.bio = bio;

    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

// Fotoğraf ekleme
router.post('/me/photos', auth, async (req, res) => {
  try {
    const { photoUrl } = req.body;
    const user = await User.findById(req.user.userId);

    user.photos.push(photoUrl);
    await user.save();

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

// Potansiyel eşleşmeleri getirme
router.get('/matches', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    const potentialMatches = await User.find({
      _id: { $nin: [...user.likes, ...user.dislikes, user._id] },
      gender: user.gender === 'male' ? 'female' : 'male'
    }).select('-password');

    res.json(potentialMatches);
  } catch (error) {
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

// Beğeni işlemi
router.post('/like/:userId', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    const likedUser = await User.findById(req.params.userId);

    user.likes.push(likedUser._id);
    await user.save();

    // Karşılıklı beğeni kontrolü
    if (likedUser.likes.includes(user._id)) {
      user.matches.push(likedUser._id);
      likedUser.matches.push(user._id);
      await user.save();
      await likedUser.save();
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

// Beğenmeme işlemi
router.post('/dislike/:userId', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    user.dislikes.push(req.params.userId);
    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

module.exports = router; 