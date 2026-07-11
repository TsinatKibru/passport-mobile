# Conventions

Four load-bearing rules. Each one protects a real failure mode you would hit this week.
Everything else — folder structure, component splitting, naming — is left to the agent's judgment.

---

## 1. Business logic lives in services, never controllers / widgets / components

This is the one non-negotiable. Every other option in this stack (Redis later, offline
later, caching later) depends on this seam existing.

**Backend (NestJS)**
- Route handlers (`@Controller`) do only: parse request → call service → return response.
- No Prisma calls in controllers. No conditional logic in controllers.
- Services own all validation, capacity checks, and database interaction.

**Mobile (Flutter)**
- Widgets call repository/service methods. No `http` or `Dio` calls inside a widget or screen file.
- All API calls go through a single repository layer (e.g., `PassportRepository`, `BoxRepository`).
  This is not offline support — it is clean architecture. Offline caching slots under the
  interface later without touching screens.

**Web Admin (Next.js)**
- Server Actions / API route handlers call service functions; they do not contain business logic.
- TanStack Query hooks fetch data; they do not transform or validate domain logic.

---

## 2. No raw colors, spacing values, or font sizes in UI code — theme tokens only

**Mobile (Flutter)**
- One `AppTheme` class (`ThemeData` + a custom `AppColors` / `AppTextStyles` extension).
- Every widget pulls from `Theme.of(context)`. Zero hardcoded `Color(0xFF...)` in screen files.
- Allowed: `AppColors.primary`. Not allowed: `Color(0xFF1A73E8)` in a widget.

**Web Admin (Next.js + shadcn/ui)**
- `tailwind.config.ts` defines a semantic token layer:
  `primary`, `surface`, `border`, `success`, `warning`, `danger` — mapped to actual hex values in one place.
- Components reference `bg-primary`, never raw hex or arbitrary Tailwind values like `bg-[#1A73E8]`.
- shadcn/ui themes via CSS variables in `globals.css` — use that mechanism, don't override it ad-hoc.

---

## 3. All location / capacity mutations go through the transaction-wrapped service method

- `LocationService.moveBox()` is the single entry point for any box move operation.
- No direct Prisma calls to `movableBox`, `passport`, or `movementLog` outside of their
  respective service files for mutation operations.
- The method must:
  1. Check destination capacity before writing.
  2. Update box location in one transaction.
  3. Cascade new location to all passports inside that box in the same transaction.
  4. Write a `MovementLog` record in the same transaction.
  5. Roll back everything on any failure — partial location updates are data corruption.

---

## 4. New API fields get added to `API_CONTRACT.md` before backend implementation

- Mobile and admin developers (or agents) read `API_CONTRACT.md` to know the shape of
  every entity. They must not discover field names by reading backend code.
- Workflow: update `API_CONTRACT.md` → review → implement in backend → implement in clients.
- This prevents the silent field-mismatch bugs that appear between two frontends and one backend.

---

## Testing expectations

**Backend (NestJS) — highest priority**
- Unit tests: `LocationService.moveBox()` and capacity-check logic specifically.
  Cover: capacity enforcement, cascade correctness, transaction rollback on failure.
- E2E tests (Supertest): core flows only:
  - Assign passport → box
  - Move box → verify passport locations updated
  - Issue passport → verify removed from box and status updated
- Skip unit-testing trivial CRUD (Room/Shelf create) — low regression risk.

**Mobile (Flutter)**
- Widget tests on the QR scan → confirm → submit flow only. This is the flow staff use
  dozens of times a day; a regression here is the most visible failure.
- No snapshot/visual tests until UI stabilizes.

**Web Admin (Next.js)**
- Component tests on the movable box table and dashboard stat cards.
- No visual regression tests in week one.

**CI requirement**
- Backend E2E tests run on every push to `main` / PR targeting `main`.
- Merge is blocked if E2E tests fail.
- This is the primary regression safety net — it catches 80% of real damage for ~2 hours of setup.

---

## Folder structure reference

```
passport-track-api/          ← NestJS backend
  src/
    modules/
      passport/              ← PassportModule: controller, service, dto, entity
      box/                   ← BoxModule
      location/              ← LocationModule (owns moveBox logic)
      room/
      shelf/
      row/
      movement-log/
    common/                  ← guards, interceptors, pipes, decorators
    prisma/                  ← PrismaService + schema
  test/
    e2e/                     ← Supertest E2E specs
    unit/                    ← LocationService unit tests

passport-track-mobile/       ← Flutter app
  lib/
    core/
      theme/                 ← AppTheme, AppColors, AppTextStyles
      routing/
    data/
      repositories/          ← PassportRepository, BoxRepository, etc.
      models/
      api/                   ← DioClient / http wrapper (one place)
    features/
      scan/
      dashboard/
      search/
    shared/
      widgets/

passport-track-admin/        ← Next.js web portal
  src/
    app/                     ← App Router pages
    components/
      ui/                    ← shadcn/ui primitives
      domain/                ← PassportTable, BoxCard, MovementLogTable
    lib/
      api/                   ← typed fetch wrappers (one place)
      hooks/                 ← TanStack Query hooks
    styles/
      globals.css            ← CSS variables / shadcn theme
    server/
      services/              ← server-side service functions (called from Server Actions)
```
