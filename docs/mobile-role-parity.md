# Mobile role parity

## Existing website and backend map

| Role / website source | Mobile destination | Shared API |
|---|---|---|
| OwnerDashboard, OwnerProfileConnectedPage | Dashboard, Restaurant | GET /owner/dashboard, GET/PUT /owner/restaurant, POST /owner/restaurant/logo, GET /restaurants/options |
| OwnerOrdersV2Page, OwnerOrderDetailPage, RiderAssignment | Orders, detail, rider assignment | GET /owner/orders[/id], PATCH /orders/:id/status, GET /deliveries/available-riders, POST /deliveries/orders/:id/assign |
| OwnerMenuPage, OwnerMenuFormPage | Menu, editor | GET /owner/menu[/id], POST /menu, PUT/DELETE /menu/:id, PATCH /menu/:id/toggle |
| OwnerAnalyticsPage | More > Analytics | GET /owner/analytics |
| RiderPremiumDashboard, RiderConnectedJobs/Detail | Home, Assigned, Current, History | GET /deliveries/my, PATCH /deliveries/:id/status |
| RiderPortalProfilePage, RiderAvailabilityPage | Profile, vehicle details, online switch | GET/PUT /roles/rider/profile, PATCH /roles/rider/availability |
| RiderPortalEarningsPage | Home / History earnings | GET /deliveries/my/earnings[?from=...] |
| AdminDashboard, AdminAnalyticsPage, AdminReportsPage | Dashboard, More | GET /admin/dashboard, /admin/analytics, /admin/reports/:type |
| AdminUsersPage, AdminApprovalsPage, AdminApplicationDetailPage | Users, More > Approvals | GET /admin/users[/id], PATCH /admin/users/:id/status, DELETE /admin/users/:id, GET /admin/applications[/id], PATCH .../approve or .../reject |
| AdminRestaurantsPage | Restaurants, owner assignment | GET /admin/restaurants[/id], GET /admin/restaurant-owners/assignable, PATCH/DELETE /admin/restaurants/:id/owner |
| AdminOrdersPage | Orders, detail | GET /admin/orders[/id], existing owner/admin order status and rider assignment APIs |
| Shared profile / authentication | All roles: Profile, theme, logout | GET/PUT /users/profile, GET /auth/me, POST /auth/login, /auth/refresh |

## Exact existing workflows

Owner: placed -> confirmed (website Accept), accepted -> confirmed (legacy), confirmed -> preparing -> ready_for_pickup. Decline uses declined, only from placed. Assignment changes the same order to rider_assigned.
Rider assignment: assigned -> picked_up (website default), optional accepted; picked_up -> out_for_delivery -> delivered. Assigned may be rejected; assigned/accepted/picked_up/out_for_delivery may fail according to backend order state. Backend updates both the assignment and shared order transactionally.

## Constraints found

There is no open delivery-job marketplace: approved online riders receive owner/admin assignments. No live GPS API exists; do not reproduce the website map placeholder. Earnings are an internal test ledger, not bank payouts. Menu images use URL fields on the website; restaurant logos have a multipart upload API. Admin cannot arbitrarily promote user roles: existing status/approval APIs govern accounts. Paid declined/cancelled orders require the existing support refund process. Existing admin list APIs are paginated; mobile must not silently show only the first page.

## Implementation plan

1. Validate restored roles through /auth/me; react to refreshed role changes and clear privileged back stacks. Reject unknown roles.
2. Keep existing customer screens and connected restaurant setup. Add shared visible-screen polling and protected API repositories.
3. Connect owner order/menu/analytics and rider assigned-delivery/availability/profile/earnings screens.
4. Reuse admin dashboard/approvals/analytics/reports and add paginated management/detail/action screens with confirmations.
5. Share existing profile/theme/logout; verify API contracts, transitions, restoration, theme, navigation, and Android compilation.
