# Social Media Module — Screen Reference

> **Why this exists.** Real screenshots could not be generated in the build
> environment (no Flutter emulator/device, `flutter_tester` headless mode
> hangs on `pumpWidget(MaterialApp(...))` for our screens). This file is the
> next best honest thing: a complete reference of every screen the module
> ships, what it renders in each state, where the widget code lives, and
> what tapping each control does. Run `flutter run` against a device and
> capture real PNGs from these screens when you want them.

Every path below is relative to `lib/features/owner/social/` unless noted.

---

## Screen 1 — Channels list (`OwnerSocialChannelsScreen`)

**Route:** `/owner/social/channels`
**File:** `presentation/screens/owner_social_channels_screen.dart`
**Nav entry:** "Social media" item in the owner drawer (`l10n.owner_nav_social`)

### Visual layout

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Social media                                            ↻     │  ← AppBar (refresh action)
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ [🅵]  Build4All Demo Page                          [● ON ]   │ │  ← SocialChannelTile
│ │       Facebook Page                                          │ │     (provider badge,
│ │       [Active]                                               │ │     name, provider,
│ └─────────────────────────────────────────────────────────────┘ │     status pill, auto-
│ ┌─────────────────────────────────────────────────────────────┐ │     publish toggle)
│ │ [📷]  @build4all_demo                              [● OFF]   │ │
│ │       Instagram                                              │ │
│ │       [Active]                                               │ │
│ └─────────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ [🏪]  Demo Commerce Catalog                        [● ON ]   │ │
│ │       Meta Commerce Catalog                                  │ │
│ │       [Token expired] ⚠                                       │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│                                          ╔═══════════════╗      │
│                                          ║ + Connect     ║      │  ← FloatingActionButton
│                                          ╚═══════════════╝      │     (.extended)
└─────────────────────────────────────────────────────────────────┘
```

### State cases the screen renders

| State | What it shows |
|---|---|
| `loading=true, channels empty` | Centered `CircularProgressIndicator` |
| `loading=false, channels empty` | `_EmptyState`: large share icon, "No channels yet", body copy, big "Connect a channel" button |
| `loading=false, channels=N` | One `SocialChannelTile` per channel, plus the FAB |
| `mutating=true` (after toggle / disconnect) | Switches/buttons disabled briefly; no spinner overlay (intentional — keeps UI snappy) |
| `error != null` | SnackBar (red, dismissed after read), state.error cleared by cubit |
| `infoMessage != null` | SnackBar (neutral), e.g. "Connected Build4All Demo Page" |

### Tap targets

| Control | Action |
|---|---|
| AppBar refresh icon | `cubit.load()` re-fetches the channel list |
| `SocialChannelTile` row tap | `context.push('/owner/social/channels/{id}', extra: channel)` |
| `SocialChannelTile` switch | `cubit.setAutoPublish(channel, v)` — PATCH `/api/owner/social/channels/{id}` with `{autoPublishEnabled: v}` |
| FAB "Connect" | Opens `ConnectChannelSheet` (modal bottom sheet) |
| ConnectChannelSheet provider row | Closes the sheet, runs `cubit.beginOAuth(provider, redirectUri)`, then pushes the WebView screen |

---

## Screen 2 — Connect channel sheet (`ConnectChannelSheet`)

**Modal:** `showModalBottomSheet`
**File:** `presentation/widgets/connect_channel_sheet.dart`

```
┌─────────────────────────────────────────────────────────────────┐
│                              ───                                │  ← drag handle
│  Connect a channel                                              │
│  Pick where Build4All should post your products.                │
│                                                                 │
│  [🅵]  Facebook Page                              →             │
│  [📷]  Instagram                                  →             │
│  [🏪]  Meta Commerce Catalog                      →             │
│  [💬]  WhatsApp Catalog                           →             │
└─────────────────────────────────────────────────────────────────┘
```

Tap a row → sheet pops → caller starts OAuth.

---

## Screen 3 — OAuth WebView (`OwnerSocialOAuthWebViewScreen`)

**Route:** `/owner/social/oauth` (transient — pushed, never bookmarked)
**File:** `presentation/screens/owner_social_oauth_webview_screen.dart`

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Connect Facebook Page                                         │  ← AppBar; back = cancel
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│           (Meta consent page — or the stub-oauth                │
│            redirect, which appears as a brief blank             │
│            then auto-completes back to the app)                 │
│                                                                 │
│                  webview_flutter WebView                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Navigation contract enforced in code:**

- Any URL that starts with `args.redirectUri` (custom scheme `build4all://oauth/social/callback`) is intercepted.
- The page extracts `code` and `state` from the query string.
- **Defence in depth:** the screen verifies `state == args.stateToken` BEFORE forwarding to the cubit. If they don't match, pops with `null` and surfaces a SnackBar ("OAuth state mismatch — refusing to continue").
- A `?error=...` parameter pops with `null` and surfaces the error.
- Back arrow → cancel (`Navigator.pop(null)`).

On success the caller's `cubit.completeOAuth(code, state)` runs, the channel list refreshes, and an `infoMessage` like "Connected Build4All Demo Page" appears.

---

## Screen 4 — Channel detail (`OwnerSocialChannelDetailScreen`)

**Route:** `/owner/social/channels/:id`
**File:** `presentation/screens/owner_social_channel_detail_screen.dart`

```
┌─────────────────────────────────────────────────────────────────┐
│ ← Build4All Demo Page                                  [🔗]     │  ← AppBar; trailing = disconnect
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Facebook Page                                                │ │  ← _MetaCard
│ │ Account: 123456_PAGE                                         │ │
│ │ Token expires: 2026-08-25 14:00                              │ │
│ │ Token suffix: …xyz4                                          │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Auto-publish on product save              [● ON ]            │ │
│ │ Every product create/update will queue a post here.          │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ ──────────────────────────────                                  │
│ Caption template                                                │
│ Use {{name}}, {{price}}, {{description}} as placeholders.       │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ New: {{name}} — {{price}}                                    │ │  ← TextField, maxLines: 5,
│ │ {{description}}                                              │ │     maxLength: 2000
│ │                                                              │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                     [💾 Save]   │  ← enabled only when dirty
│                                                                 │
│ ──────────────────────────────                                  │
│ [ Enable ] / [ Disable ]                                        │  ← _StatusActions (mutually-
│                                                                 │     exclusive based on status)
│                                                                 │
│ ⚠ Last error:                                                   │
│   META_190 — Token expired                                      │  ← _LastErrorPanel (only when
└─────────────────────────────────────────────────────────────────┘     lastError != null)
```

### Disconnect dialog

Trailing 🔗 button → `AlertDialog`:

> **Disconnect channel?**
> This stops Build4All from posting to *Build4All Demo Page* and removes its configuration. Pending unposted items will be cancelled.
> [Cancel] [Disconnect]

---

## Screen 5 — Item social panel (`ItemSocialPanel`)

**Embedded in:** the existing product create/edit screen (caller pumps it in)
**File:** `presentation/widgets/item_social_panel.dart`

```
┌─────────────────────────────────────────────────────────────────┐
│ Social media                                                    │
│ Choose which channels publish this product when it is saved.    │
│                                                                 │
│ [🅵]  Build4All Demo Page          [ Auto (on) ▾]      [📤]      │  ← per-channel row
│         + Edit caption override                                 │
│         Will publish on save                                    │
│                                                                 │
│ [📷]  @build4all_demo              [ Never ▾]          [📤]      │
│         + Add caption override                                  │
│         Will NOT publish on save                                │
│                                                                 │
│ ──────────────────                                              │
│ Recent posts                                                    │
│ ✓ Build4All Demo Page                                           │
│   https://facebook.com/123/posts/456              attempt 1/5   │
│ ⚠ @build4all_demo                                               │
│   Failed: META_190 — Token expired                attempt 5/5   │
│ ⏰ Build4All Demo Page                                           │
│   Queued — waiting for dispatcher                               │
└─────────────────────────────────────────────────────────────────┘
```

### Tri-state override chip

Tap "Auto (on) ▾" → `PopupMenuButton`:

- Inherit channel default
- Always publish
- Never publish

Each maps to `cubit.setAutoPublishOverride(channelId, null|true|false)`.

### Caption override

Tapping "+ Edit caption override" reveals a 4-line `TextField` (max 2000 chars) and a Save-override button (enabled only when dirty).

### Publish-now (📤)

Greyed out unless `channel.status == ACTIVE`. Tap → `cubit.publishNow(channelId)` → POST `/api/owner/items/{itemId}/social/publish-now?channelId={...}`. New post prepended to the recent-posts list with `status=PENDING`.

### Empty state

When the tenant has no active feed-capable channels: `Icons.share_outlined` + "No feed-capable channels connected. Connect one from the Social media section."

---

## Screen 6 — Channel post history (`OwnerSocialPostHistoryScreen`)

**Route:** `/owner/social/channels/:id/history`
**File:** `presentation/screens/owner_social_post_history_screen.dart`

```
┌─────────────────────────────────────────────────────────────────┐
│ ← History: Build4All Demo Page                                  │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Build4All Demo Page                            SUCCEEDED    │ │
│ │ Item #42                                                    │ │
│ │ ↗ https://facebook.com/123/posts/456                        │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ Build4All Demo Page                            FAILED       │ │
│ │ Item #43                                                    │ │
│ │ Failed: META_190 — Token expired                            │ │  ← red text
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ Build4All Demo Page                            PENDING      │ │
│ │ Item #44                                                    │ │
│ └─────────────────────────────────────────────────────────────┘ │
│ ↻ pull to refresh                                               │
└─────────────────────────────────────────────────────────────────┘
```

Tap permalink → `launchUrl(..., LaunchMode.externalApplication)` opens it in the system browser.
Empty state: `Icons.history_outlined` + "No posts yet for this channel."

---

## Screen 7 — Instagram compat badge (`InstagramCompatBadge`)

**Embedded next to image picker in the product editor.**
**File:** `presentation/widgets/instagram_compat_badge.dart`

```
Accepted:                              Rejected:
┌──────────────────────────────┐       ┌──────────────────────────────┐
│ ✓ OK for Instagram           │       │ ⚠ Too tall for IG            │  ← ActionChip
└──────────────────────────────┘       └──────────────────────────────┘
   tooltip: "1080 × 1080 —             tap → bottom sheet:
            aspect 1.00:1"             "Instagram only accepts photos
                                       with aspect ratio down to 4:5
                                       (portrait). Crop closer to square."
```

Verdict computed locally by `InstagramCompat.check(width, height, bytes, mimeType)`. No round-trip required.

---

## Screen 8 — Catalog currency badge (`CatalogCurrencyBadge`)

**Embedded next to each catalog channel row in the product editor.**
**File:** `presentation/widgets/catalog_currency_badge.dart`

```
Match:                                 Mismatch:
┌──────────────────────────────┐       ┌──────────────────────────────────────┐
│ ✓ Demo Commerce Catalog OK   │       │ ⚠ Demo Commerce Catalog currency     │  ← ActionChip
└──────────────────────────────┘       │   mismatch                            │
   tooltip: "Demo Commerce              └──────────────────────────────────────┘
            Catalog is in USD"          tap → bottom sheet explaining Meta drops
                                        items with mismatched currency.
```

---

## Screen 9 — Plan B feed tile (`PlanBFeedTile`)

**Embedded in catalog channel detail (when `channel.provider.isCatalog`).**
**File:** `presentation/widgets/plan_b_feed_tile.dart`

```
Before issue:                          After issue:
┌─────────────────────────────────────┐ ┌─────────────────────────────────────┐
│ ☁ Plan B: catalog pull feed         │ │ ☁ Plan B: catalog pull feed         │
│                                     │ │                                     │
│ A signed URL Meta can pull on a     │ │ A signed URL Meta can pull on a     │
│ schedule when our push is offline.  │ │ schedule when our push is offline.  │
│                                     │ │                                     │
│ [🔑 Issue feed URL]                 │ │ https://api.../feed/7.xml?exp=...   │
└─────────────────────────────────────┘ │                       &sig=...      │
                                       │ Expires: 2026-06-25 14:00            │
                                       │ [📋 Copy] [↻ Re-issue]               │
                                       └─────────────────────────────────────┘
```

Issue → backend signs URL with HMAC-SHA256 over `(ownerProjectId | exp)`. Copy → `Clipboard.setData` + SnackBar "Feed URL copied".

---

## Drawer wiring (the entry point)

`lib/app/router/router.dart`'s `_OwnerNavWrapper` exposes 5 destinations after Slice 2's change:

```
┌─────────────────────────────────────────────────────────────────┐
│ ⌂  Home                                                         │
│ ▦  My Apps                                                      │
│ ⊰  Social media                              ← new in Slice 2   │
│ 🔔 Notifications                                                │
│ 👤 Profile                                                      │
└─────────────────────────────────────────────────────────────────┘
```

Tapping "Social media" navigates to `/owner/social/channels` (Screen 1).

---

## How to capture real screenshots

```bash
# 1. Spin up the BE locally (Postgres + run the Spring Boot app with
#    social.enabled=true, social.publisher.provider=stub).
# 2. From build4all-manager-frontend:
flutter run -d <device-id>
# 3. Sign in as an OWNER, open the drawer, tap "Social media".
# 4. Use the device screenshot key combo (or `flutter screenshot`).
```

Every screen here corresponds 1:1 to a real `Scaffold` / `Card` / widget in
the committed code — what you'd capture matches the layouts above modulo the
host app's theme palette (`ThemeCatalog.emerald` / `violet` / `amber`).
