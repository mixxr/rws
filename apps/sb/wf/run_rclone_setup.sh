mkdir -p ~/.config/rclone/
echo "[r2]
type = s3
provider = Cloudflare
access_key_id = d4f4c5e6069f8817b00920366c47c6ef
secret_access_key = $R2_CLONE_SECRET
endpoint = https://7bf21e6595296f2bba6b11290649d9b0.r2.cloudflarestorage.com
acl = private" > ~/.config/rclone/rclone.conf
ls -la ~/.config/rclone/rclone.conf
if grep -qF "$R2_CLONE_SECRET" ~/.config/rclone/rclone.conf; then
  echo "R2_CLONE_SECRET found"
else
  echo "R2_CLONE_SECRET not found. Exiting..."
  exit 1
fi
