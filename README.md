# Termux IP Address Changer 🔁

এই স্ক্রিপ্টটি **Termux** (Android) এ প্রতি **২ সেকেন্ড** পরপর আপনার ডিভাইসের লোকাল IP ঠিকানা পরিবর্তন করে।

> ⚠️ শুধুমাত্র **শিক্ষামূলক (educational) উদ্দেশ্যে** ব্যবহার করুন।

---

## 🔧 কীভাবে ব্যবহার করবেন

### ১. Termux-এ নিচের কমান্ড চালান:

```bash
pkg update && pkg upgrade -y
pkg install git -y
git clone https://github.com/yourusername/termux-ip-changer
cd termux-ip-changer
chmod +x ip_changer.sh
./ip_changer.sh
```

> আপনি যদি root ব্যবহারকারী না হন, তাহলে এই স্ক্রিপ্ট কাজ করবে না।

---

## ⚠️ গুরুত্বপূর্ণ

- এই স্ক্রিপ্টটি **Bluestacks 5** সাপোর্ট করে, কিন্তু সেখানে IP পরিবর্তন কাজ করবে কিনা তা নির্ভর করে rooted environment-এর উপর।
- এটি শুধুমাত্র **লোকাল নেটওয়ার্ক IP (LAN)** পরিবর্তন করে। এটি **public IP (ISP)** পরিবর্তন করে না।

---

## 📜 লাইসেন্স

এই প্রজেক্টটি MIT লাইসেন্সে উন্মুক্ত।
