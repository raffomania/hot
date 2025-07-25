# Authentication Specification

## Overview

This document outlines the shared password authentication approach for the Hot TV show tracking app. Given the small user base (≤5 people) and focus on simplicity, we use a single shared password set via environment variable.

The approach: Custom Session-Based Authentication Plug.

## Requirements

- **Small Scale**: Maximum 5 users
- **Shared Access**: Single password for all users
- **Environment Configuration**: Password set via environment variable
- **Simple Implementation**: Minimal code complexity
- **No User Management**: No individual user accounts or registration

## Implementation Plan

The implementation is split into three milestones for test-driven incremental development:

### Milestone 1: Write Failing Authentication Test

**Goal**: Create a comprehensive test that verifies no protected pages can be accessed without authentication.

**Components**:
1. **Integration Test** (`test/hot_web/authentication_test.exs`)
   - Test accessing all protected routes (`/shows`, `/shows/:id`, `/board`) without authentication
   - Verify redirects to `/auth/login` for all protected pages
   - Test both regular HTTP requests and LiveView mounts
   - Include test for login page accessibility

**Deliverable**: A comprehensive test suite that fails because authentication infrastructure doesn't exist yet.

### Milestone 2: Authentication Stub (Deny All Access)

**Goal**: Create basic authentication infrastructure that blocks all access and redirects to an empty login page.

**Components**:
1. **Authentication Module** (`lib/hot_web/shared_auth.ex`)
   - Plug function that always denies access (no authentication logic yet)
   - LiveView `on_mount` callback for session checking
   - Redirects all unauthenticated requests to `/auth/login`
   - Stores return path for post-login redirect

2. **Basic Auth Controller** (`lib/hot_web/controllers/auth_controller.ex`)
   - Minimal controller with login action
   - Renders empty login page

3. **Empty Login Template** (`lib/hot_web/controllers/auth_html/login.html.heex`)
   - Completely empty page (placeholder)

4. **Router Configuration**
   - Add protected pipeline with authentication plug
   - Add basic auth routes
   - Protect existing routes

**Router Configuration**:
```elixir
# Protected pipeline for authenticated routes
pipeline :protected do
  plug :browser
  plug HotWeb.SharedAuth
end

# Auth routes (public)
scope "/auth", HotWeb do
  pipe_through :browser
  get "/login", AuthController, :login
  post "/login", AuthController, :authenticate
  get "/logout", AuthController, :logout
end

# Protected routes
scope "/", HotWeb do
  pipe_through :protected
  
  live_session :protected, on_mount: HotWeb.SharedAuth do
    live "/shows", ShowLive.Index, :index
    live "/shows/:id", ShowLive.Show, :show
    live "/board", BoardLive.Index, :index
  end
end
```

**Deliverable**: All existing routes require authentication but login page is empty (no way to authenticate yet). The test from Milestone 1 should now pass.

### Milestone 3: Full Authentication Implementation + Tests

**Goal**: Complete the authentication system with password validation and comprehensive tests.

**Components**:
1. **Complete Authentication Module**
   - Add session checking logic to both plug and on_mount
   - Handle authenticated users properly
   - Password validation function

2. **Full Auth Controller**
   - Login form display
   - Password validation against `SHARED_PASSWORD` env var
   - Session management and logout
   - Error handling and flash messages

3. **Complete Login Template**
   - Password form using HotWeb components
   - Error display and styling
   - Integration with TailwindCSS

4. **Additional Tests**
   - Plug unit tests (authenticated/unauthenticated scenarios)
   - Controller tests (login success/failure, logout)
   - Environment variable configuration tests
   - Extend existing integration test to cover successful authentication

**Environment Configuration**:
```bash
# in .env and .env.example
SHARED_PASSWORD=dev_password_123
```

## Implementation Details

### Authentication Flow

1. **Unauthenticated Access**: User visits protected route
2. **Redirect**: Automatic redirect to `/auth/login`
3. **Login Form**: User enters shared password
4. **Validation**: Server validates against environment variable
5. **Session**: Set authentication flag in session
6. **Redirect**: Return to originally requested page
7. **Access**: User has access until session expires or logout

### Security Considerations

1. **Password Security**: Shared password stored only in environment variables
2. **Session Security**: Standard Phoenix session handling with CSRF protection
3. **Secure Comparison**: Use `Plug.Crypto.secure_compare/2` to prevent timing attacks

### Integration with Existing App

#### LiveView Integration
- Authentication plug runs before LiveView mounts
- `on_mount` callback provides additional session checking for persistent connections
- Authenticated state available in all LiveViews
- No changes needed to existing LiveView components

## File Structure

```
lib/hot_web/
├── shared_auth.ex               # Authentication module (plug + on_mount)
├── controllers/
│   ├── auth_controller.ex       # Login/logout controller
│   └── auth_html/
│       └── login.html.heex      # Login form template
└── router.ex                    # Updated with auth routes
```

## Success Criteria

- [ ] Single shared password authenticates all users
- [ ] Password configured via environment variable
- [ ] Clean login form matching app design
- [ ] Session persists across page navigation
- [ ] Automatic redirect after login
- [ ] password only stored in memory
- [ ] Works seamlessly with existing LiveView pages
