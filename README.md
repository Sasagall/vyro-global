# VYRO — mobile-first social video PWA

A no-cost-start prototype designed for a global short-video community. It runs in a browser and can be installed as a PWA on compatible Android/iOS browsers. It is **not yet a production social network**.

## Included
- Responsive mobile interface and bottom navigation
- German/English/Italian language toggle (English is the default)
- Global-ready category taxonomy: comedy, music, sports, gaming, travel, food, education, beauty, business, news and art
- Moderation-first database defaults: new videos and comments remain pending until approved
- Starter user-block table and privacy/safety launch checklist
- Demo feed, likes, follow toggles, local comments
- Local profile storage
- Video URL preview/publishing (a direct, browser-playable MP4 URL is needed)
- Demo wallet with no real-money balance or payouts
- PWA manifest and service worker for caching app shell
- `supabase-schema.sql` with starter tables and row-level security policies

## Run locally
Service workers/PWA install require HTTPS or localhost. From this folder run:

```bash
python3 -m http.server 8080
```

Open `http://localhost:8080` in your browser. For a phone test on the same Wi-Fi, use your computer's local IP address and port 8080; PWA install may require HTTPS, so use localhost for desktop testing or deploy to a trusted HTTPS host.

## Install on phone
- Android: deploy to an HTTPS host, open the site in Chrome, choose **Install app** / **Add to Home screen**.
- iPhone: deploy to an HTTPS host, open in Safari, tap **Share → Add to Home Screen**.

## Supabase backend (optional next step)
1. Create a Supabase project.
2. Open SQL Editor and run `supabase-schema.sql`.
3. Configure email authentication and allowed redirect URLs.
4. Create a **private** Storage bucket called `videos` and add policies that only permit a signed-in user to upload/delete objects under their own `auth.uid()` folder. Keep public access off until a moderation/review flow is implemented.
5. Add the Supabase URL and **anon/publishable key** to a frontend configuration when the app is integrated. Never expose the `service_role` key.
6. Add server-side moderation before making uploads public. In the provided schema, new videos/comments are pending and only approved videos/comments are visible publicly.

The current demo is not connected to Supabase; data is stored in the current browser only. Database policies are a starting point and should be security-reviewed and tested before a public launch.

## Global launch plan (organic growth, no paid ads)
1. Start with a small opt-in beta community and invite creators directly; encourage sharing but do not reward spam or fake engagement.
2. Publish clear community rules, copyright reporting and appeal channels before public uploads.
3. Add language-aware recommendations and let users choose global, regional or followed-creator feeds. Do not infer sensitive traits.
4. Add real revenue before any viewer reward pool; publish transparent eligibility, caps, fraud checks and payout terms. Never promise earnings before funding exists.
5. Scale media using limits, adaptive transcoding and a CDN only when real usage justifies the cost. A free tier is for testing, not unlimited global video delivery.

## Production checklist before public launch
- Real auth, account deletion/export, email verification, rate limits and abuse controls
- Server-side video upload validation, file-size/duration limits, transcoding, thumbnails, CDN and storage cost controls
- Moderation/report queue, blocking, appeals, copyright/takedown process, age controls and community guidelines
- Privacy policy, terms, GDPR data processing/legal basis, cookie/analytics consent where needed, age safeguards, regional privacy rules and EU Digital Services Act obligations review
- Payments through a compliant provider; country-by-country eligibility/tax review; no real payout logic is implemented
- App Store / Google Play packaging, device testing, accessibility and crash monitoring
- Confirm name, trademark, domain and store listing availability before branding investment

## Important limits
- Demo likes/comments/follows are local state and are not shared between devices.
- Sample video cards are visual placeholders; actual video playback requires a direct video URL.
- The create form adds a video link locally, not a file upload.
- The wallet is illustrative only. It does not represent cash, credits, or a promise of earnings.
- No claim is made that the prototype is production-ready or fully secure for a public launch.
