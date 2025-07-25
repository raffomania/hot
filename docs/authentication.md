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
- **No Database Models**: No user tables, schemas, or database-backed authentication

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

2. **Basic Auth LiveView** (`lib/hot_web/auth_live/login.ex`)
   - Minimal LiveView module for login page
   - Renders empty login page (placeholder)

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
  live "/login", AuthLive.Login, :login
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

### Milestone 3: Authentication Logic Implementation + Tests

#### Goal
Implement the core authentication functionality with password validation and comprehensive tests.

#### Important
This implementation uses only session-based authentication with environment variables. No user database models, tables, or schemas should be created.

#### Components

##### Complete Authentication Module (`lib/hot_web/shared_auth.ex`)
- Add session checking logic to both plug and on_mount
- Handle authenticated users properly
- Password validation function against `SHARED_PASSWORD` env var
- Session management (authentication/logout) using Phoenix sessions only

##### Integration Tests (extend `test/hot_web/authentication_test.exs`)
- Test authenticated user access (session contains auth flag)
- Test unauthenticated user redirect
- Test password validation function with correct/incorrect passwords
- Test on_mount callback behavior for LiveView sessions
- Test successful authentication flow end-to-end
- Test session persistence across requests
- Test logout functionality

#### Test Specifications
- Password validation tests should assert correct password returns `:ok`, incorrect returns `:error`
- Session tests should assert authenticated session allows access, missing session redirects
- Integration tests should assert complete login flow works from protected route → login → back to protected route

#### Deliverable
Core authentication logic is functional with comprehensive test coverage, but no login UI yet.

### Milestone 4: Login Page Implementation + Tests

#### Goal
Create the login form interface and complete the authentication system.

#### Components

##### Full Auth LiveView (`lib/hot_web/auth_live/login.ex`)
- Login form display with password input
- Form submission and event handling
- Error display with flash messages
- Success redirect to original requested page
- Logout functionality

##### LiveView Tests (`test/hot_web/auth_live/login_test.exs`)
- Test login form renders correctly
- Test successful login with correct password
- Test failed login with incorrect password shows error
- Test form validation and error messages
- Test redirect behavior after successful authentication
- Test logout functionality

#### Test Specifications
- Form rendering tests should assert password input field and submit button are present
- Success flow tests should assert correct password submission sets session and redirects
- Error flow tests should assert incorrect password shows error message and doesn't set session
- Logout tests should assert session is cleared and user is redirected appropriately

#### Deliverable
Complete authentication system with functional login page and full test coverage.

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
├── auth_live/
│   └── login.ex                 # Login LiveView module
└── router.ex                    # Updated with auth routes
```