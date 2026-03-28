## Plan: Upgrade Booking Session Flow (No UI Redesign)

This plan keeps the existing visual design but replaces hardcoded booking behavior with provider-driven Supabase data, including package prefill, date/slot live updates, and correct price calculation from selected package data. It is phased for checkpoint reviews before coding so you can validate contracts, state transitions, and edge-case handling (timezone, empty/error states, realtime lifecycle) incrementally and safely.

### Steps 6 steps, 5–20 words each
1. Validate table contracts and current gaps in [booking_repository.dart](lib/features/booking/repository/booking_repository.dart), [slot_model.dart](lib/features/booking/models/slot_model.dart), and [package_model.dart](lib/features/booking/models/package_model.dart) against `public.packages`/`public.gym_slots`.
2. Redesign `BookingProvider` state lifecycle in [booking_provider.dart](lib/features/booking/providers/booking_provider.dart) for `selectedPackage`, `selectedDate`, slot stream subscription, and explicit `initializeBookSession`.
3. Update package card interaction in [packages_screen.dart](lib/features/booking/views/packages_screen.dart): change label to **Book**, call `selectPackage`, then navigate with prefilled context.
4. Refactor [book_and_pay_screen.dart](lib/features/booking/views/book_and_pay_screen.dart) to consume provider state (package banner, date chips, slot grid, summary totals) without changing layout structure.
5. Standardize refresh + realtime behavior across both screens using `RefreshIndicator`, deterministic stream attach/detach points, and `refreshBookSession` orchestration.
6. Add targeted provider/repository/widget tests under [test](test) for prefill, date filtering, realtime updates, and fallback states; checkpoint acceptance criteria before payment integration.

### Data/State Flow
- Source of truth: `BookingProvider` owns `selectedPackage`, `selectedDate`, `selectedSlot`, `slots`, `isLoading`, `errorMessage`.
- Navigation flow: tap package in [packages_screen.dart](lib/features/booking/views/packages_screen.dart) -> `selectPackage` -> open [book_and_pay_screen.dart](lib/features/booking/views/book_and_pay_screen.dart) -> `initializeBookSession` ensures fresh slots stream.
- Repository flow: `fetchPackages`/`streamPackages` from `packages`; `fetchSlotsByDate`/`streamSlotsByDate` from `gym_slots`, sorted by `start_time`.
- Pricing flow: derive subtotal from `selectedPackage.price`; compute displayed tax/total from configured formula; no payment write-side changes now.

### Error/Empty/Loading Handling
- Loading: keep current spinner style; separate “initial load” from “refresh in progress” to avoid flicker.
- Empty slots: show existing empty-state text when selected date has no available `gym_slots`.
- Errors: show non-blocking inline retry affordance on Book page while preserving currently shown data.
- Stale selection guards: clear `selectedSlot` when date changes or selected slot no longer appears in realtime payload.
- Missing prefill fallback: if `selectedPackage` is null on Book page entry, show clear error state and safe back navigation.

### Timezone and Date Filtering Concerns
- `gym_slots.start_time` is `timestamp with time zone`; define canonical comparison timezone (gym-local or device-local) before coding.
- Avoid local-only boundary bugs: convert date boundaries consistently when building `.gte/.lte` queries in [booking_repository.dart](lib/features/booking/repository/booking_repository.dart).
- Ensure stream filter logic matches fetch logic exactly (same boundary strategy), preventing mismatch between initial fetch and realtime updates.
- Confirm display formatting (`intl`) uses intended timezone for date chips and time labels.

### Acceptance Criteria / Test Checklist
- [ ] Package button text in [packages_screen.dart](lib/features/booking/views/packages_screen.dart) is **Book** everywhere.
- [ ] Tapping a package opens [book_and_pay_screen.dart](lib/features/booking/views/book_and_pay_screen.dart) with matching package name/price/sessions.
- [ ] Book page date/time options come from Supabase `public.gym_slots`, not hardcoded lists.
- [ ] Pull-to-refresh on both screens re-fetches latest package/slot data successfully.
- [ ] Realtime updates update slot availability live while Book page is visible.
- [ ] Date change reloads and re-subscribes slots for that date only.
- [ ] Price summary always reflects selected package price and expected rounding rules.
- [ ] Empty-state and error-state behavior is visible, recoverable, and non-crashing.
- [ ] Timezone edge cases (late-night UTC/local boundary) return correct slots for selected day.
- [ ] Existing booking creation/payment code path remains untouched for this phase.

### Further Considerations
1. Which timezone is authoritative for slot-day grouping? Option A gym timezone / Option B device timezone / Option C UTC-normalized display.
2. Should tax remain fixed at 8% in UI summary now, or be configurable from backend/app constants?
3. Approve this as Draft v1 checkpoint plan, then I will refine with exact test-case matrix per phase.

