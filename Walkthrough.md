# Arkpush — API Functionality Walkthrough

## Part 1: How the Legacy API Works

The legacy API is the **original Postal v1 API**, designed from the start for sending emails over HTTP. It was originally built using a framework called **Moonrope** (now unmaintained), but has been reimplemented as standard Rails controllers while preserving backward compatibility.

### Key Differences from New API v1

| Aspect | Legacy API | New API v1 |
|--------|-----------|------------|
| **Auth** | `X-Server-API-Key` header (server credential) | `Authorization: Bearer <key>` (user API key) |
| **Scope** | Server-level only (send + query messages) | Full platform management |
| **Status codes** | Always returns `200 OK` — real status in JSON body | Uses proper HTTP status codes (200, 201, 401, 403, 404, 422) |
| **Params** | JSON body OR `params` field (form-encoded) | Standard Rails params |
| **Response format** | `{ status, time, flags, data }` | `{ status, data }` or `{ status, error, data }` |

### Authentication Flow

```
POST /api/v1/send/message
Headers: X-Server-API-Key: <credential.key>
```

The legacy API authenticates at the **server level** (not user level):

1. Client sends `X-Server-API-Key` header
2. `LegacyAPI::BaseController#authenticate_as_server` looks up `Credential.where(type: "API", key: key)`
3. If the credential is valid and the server is not suspended → `@current_credential` is set
4. All subsequent operations are scoped to that server

### Endpoints

#### `POST /api/v1/send/message` — Send Structured Email
Accepts a JSON body with structured fields:
```json
{
  "to": ["user@example.com"],
  "cc": ["cc@example.com"],
  "bcc": ["bcc@example.com"],
  "from": "sender@yourdomain.com",
  "subject": "Hello",
  "plain_body": "Plain text content",
  "html_body": "<p>HTML content</p>",
  "tag": "order-confirmation",
  "headers": { "X-Custom": "value" },
  "attachments": [
    { "name": "file.pdf", "content_type": "application/pdf", "data": "<base64>" }
  ]
}
```

Validates: recipients exist, content exists, from address is authenticated against a verified domain, max 50 per recipient type, attachments have name+data.

Returns message IDs and tokens for each recipient:
```json
{
  "status": "success",
  "data": {
    "message_id": "<msg-id>",
    "messages": {
      "user@example.com": { "id": 123, "token": "abc123..." }
    }
  }
}
```

#### `POST /api/v1/send/raw` — Send Raw MIME Email
Accepts base64-encoded raw MIME data:
```json
{
  "rcpt_to": ["user@example.com"],
  "mail_from": "sender@yourdomain.com",
  "data": "<base64-encoded-mime>"
}
```

#### `POST /api/v1/messages/message` — Retrieve Message Details
Returns message details with optional `_expansions` for selective data loading:
- `status`, `details`, `inspection`, `plain_body`, `html_body`, `attachments`, `headers`, `raw_message`, `activity_entries`

#### `POST /api/v1/messages/deliveries` — Retrieve Delivery Attempts
Returns all SMTP delivery attempts for a message with status, output, and timestamps.

### TrackingMiddleware

The `TrackingMiddleware` intercepts requests **before Rails** (inserted before `ActionDispatch::HostAuthorization`):
- **Open tracking**: `GET /img/<server_token>/<message_token>` → serves 1px tracking pixel, records load event
- **Click tracking**: `GET /<server_token>/<link_token>` → records click event, triggers `MessageLinkClicked` webhook, 307 redirects to original URL
- Only activates when `X-Postal-Track-Host: 1` header is present
- Explicitly excludes `/api/` paths via negative lookahead `(?!api)`

### Legacy API Test Coverage (4 spec files, ~30+ test cases)

| Spec File | Tests |
|-----------|-------|
| `send/message_spec.rb` | Auth errors, validation (no recipients, no content, too many addresses, unauthenticated from, attachment errors), successful send with full message verification |
| `send/raw_spec.rb` | Raw MIME sending with domain authentication |
| `messages/message_spec.rb` | Message retrieval with expansions |
| `messages/deliveries_spec.rb` | Delivery attempt retrieval |

> [!NOTE]
> The legacy API always returns HTTP `200 OK`. Success vs. failure is indicated by the `status` field in the JSON body (`"success"`, `"error"`, or `"parameter-error"`).

---

## Part 2: New API v1 Verification

### Test Status — ✅ All Passing

| CI Run | Commit | Result |
|--------|--------|--------|
| Empty body bug | `1ce3630` — `test-troubleshooting` | ❌ 5 failures |
| Auth fix | `3899732` — `fix(api): correctly disable authie` | ❌ 2 failures |
| **Final** | `897e483` — `fix(specs): use admin user for org create, fix server test data` | ✅ **748 examples, 0 failures** |

### What Was Fixed

1. **`auth_session_enabled?` typo** → corrected to `auth_session_enabled?`
2. **Test user not admin** → fixed with `create(:user, admin: true)`
3. **Duplicate server permalink** → fixed with `permalink: 'new-server'`
4. **Missing server mode** → fixed with `mode: 'Live'`

---

## Part 3: Complete New API v1 Endpoint Reference

**15 controllers** with **~50+ endpoints** covering the entire platform.

### Authentication & User Management

| Controller | Endpoints | Description |
|------------|-----------|-------------|
| **SessionsController** | `POST /api/v1/sessions` | Login (email+password → API key) |
| | `DELETE /api/v1/sessions` | Logout |
| | `POST /api/v1/sessions/reset` | Begin password reset |
| | `PUT /api/v1/sessions/reset` | Finish password reset |
| **UserController** | `GET /api/v1/user` | View own profile |
| | `PATCH /api/v1/user` | Update own profile |
| **UserAPIKeysController** | `GET /api/v1/user/api_keys` | List API keys |
| | `POST /api/v1/user/api_keys` | Create new API key |
| | `DELETE /api/v1/user/api_keys/:id` | Revoke API key |
| **UsersController** *(admin)* | `GET/POST/PATCH/DELETE /api/v1/users` | Full CRUD for all platform users |

### Organizations & Servers

| Controller | Endpoints | Description |
|------------|-----------|-------------|
| **OrganizationsController** | `GET/POST/PATCH/DELETE /api/v1/organizations` | Full CRUD |
| | `PATCH /api/v1/organizations/:id/settings` | Update org settings |
| **ServersController** | `GET/POST/PATCH/DELETE .../organizations/:id/servers` | Full CRUD |
| | `POST .../servers/:id/suspend` | Suspend server |
| | `POST .../servers/:id/unsuspend` | Unsuspend server |

### Domains & DNS

| Controller | Endpoints | Description |
|------------|-----------|-------------|
| **DomainsController** | `GET/POST/DELETE .../domains` | CRUD (org-level and server-level) |
| | `POST .../domains/:id/verify` | Verify domain (DNS or Email) |
| | `POST .../domains/:id/check` | Check SPF/DKIM/MX records |
| **TrackDomainsController** | `GET/POST/DELETE .../track_domains` | CRUD for click/open tracking domains |
| | `POST .../track_domains/:id/toggle_ssl` | Toggle SSL |
| | `POST .../track_domains/:id/check` | DNS check |

### Messages

| Controller | Endpoints | Description |
|------------|-----------|-------------|
| **MessagesController** | `GET .../messages` | List (filter by to/from/status/tag) |
| | `GET .../messages/:id` | Show full message (headers, body, attachments) |
| | `GET .../messages/:id/activity` | Activity log |
| | `GET .../messages/:id/deliveries` | SMTP delivery attempts |
| | `POST .../messages/:id/retry` | Retry failed delivery |
| | `POST .../messages/:id/cancel_hold` | Release held message |

### Webhooks & Infrastructure

| Controller | Endpoints | Description |
|------------|-----------|-------------|
| **WebhooksController** | `GET/POST/PATCH/DELETE .../webhooks` | Full CRUD |
| | `GET .../webhooks/history` | Delivery history |
| | `GET .../webhooks/history/:uuid` | Single request detail |
| **InvitesController** | `GET/POST/DELETE .../invites` | Manage team invitations |
| **IPPoolsController** *(admin)* | `GET/POST/PATCH/DELETE /api/v1/ip_pools` | Full CRUD |
| **IPPoolRulesController** | `GET/POST/PATCH/DELETE .../ip_pool_rules` | Org-level and server-level rules |
| **DocsController** | `GET /api/v1/docs` | Interactive Swagger UI documentation |

### Confirmed Working

- ✅ Bearer token authentication via `UserAPIKey`
- ✅ Organization CRUD (list, create)
- ✅ Server CRUD (list, create under organization)
- ✅ Session creation (email/password → API key)
- ✅ Error handling (invalid credentials → 401)
- ✅ Legacy send API (all tests pass)
- ✅ **All 748 tests green** (models, SMTP server, message processing, webhook delivery, DNS, etc.)
