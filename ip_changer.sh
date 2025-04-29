#!/data/data/com.termux/files/usr/bin/bash

# IP Address পরিবর্তনের স্ক্রিপ্ট (প্রতি 2 সেকেন্ডে)
# শুধুমাত্র Educational Purpose-এ ব্যবহার করুন

# প্রয়োজনীয় প্যাকেজ ইন্সটল
pkg install -y tsu
pkg install -y busybox

# চেক করুন আপনি root access পাচ্ছেন কিনা
if ! command -v tsu >/dev/null; then
  echo "🔴 tsu (root shell) ইনস্টল হয়নি বা root access নেই!" >&2
  exit 1
fi

# নেটওয়ার্ক ইন্টারফেস নাম বের করা (যেমন: wlan0)
IFACE=$(ip route | awk '/default/ {print $5}')

# চেক করা হচ্ছে ইন্টারফেস সঠিক আছে কিনা
if [ -z "$IFACE" ]; then
  echo "🔴 Network interface খুঁজে পাওয়া যায়নি!" >&2
  exit 1
fi

# IP পরিবর্তনের লুপ
while true; do
  # র‍্যান্ডম 1 থেকে 254 পর্যন্ত শেষ অষ্টক তৈরি
  LAST_OCTET=$((RANDOM % 254 + 1))
  NEW_IP="192.168.43.$LAST_OCTET"

  echo "🟢 নতুন IP সেট করা হচ্ছে: $NEW_IP"
  tsu -c "ifconfig $IFACE $NEW_IP netmask 255.255.255.0"

  sleep 2
done
