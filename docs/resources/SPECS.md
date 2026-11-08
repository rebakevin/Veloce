# Veloce — Product Specification

**Version:** 0.12 · **Date:** 2026-10-24
**Source:** the Veloce HTML mock (mobile prototype), the product brief, and the owner's answers to two rounds of questions.

> The brief calls the product "Felodge". The mock and the project are named **Veloce**, so this document uses Veloce. Rename freely.

## How to read this document

| Tag | Meaning |
| --- | --- |
| **[Mock]** | Already built in the prototype; recorded as is. |
| **[New]** | Decided in the brief or answers; not in the mock yet. |
| **[Change]** | The mock behaves differently; the decision wins. |
| **[O#]** | Open question; see section 13 (none open at the moment). |

This is a school project. MoMo payments, identity and document verification, and Veloce's licence to hold funds are all **assumed or simulated**. The design should still isolate each of them behind an interface (section 11) so a real provider can replace the simulation.

---

## 1. Product overview

Veloce is a peer-to-peer car rental marketplace for Kigali. Car owners list cars that sit idle; renters find a car for their dates, request it, and pay through Mobile Money. Veloce holds the money between payment and handover: the owner is paid the rental fee only after **both** sides confirm pickup, and the caution fee (security deposit) stays on hold until the return is settled.

**Core promise**

- Renters: cars from local owners, a clear total before they commit, and a caution fee that comes back when the car returns in good shape.
- Owners: full control over who drives their car, guaranteed payment at handover, and a caution fee that protects them against damage.

**Fixed decisions**

- City: Kigali only. Currency: RWF. Pricing: per day. Language: English only.
- Self-drive only; the renter must hold a valid driving licence.
- Payment: MTN MoMo only, simulated [Change: the mock also offered Airtel Money and bank payouts].
- Notifications: in-app only. There is no in-app chat: owner and renter talk outside the app.
- Sign-in: email and password, plus Google sign-in [Change].
- Insurance: handled entirely by the car owner. Veloce takes no part in insurance and carries no damage liability.
- No admin panel. Problems are handled between the two parties, or by contacting support outside the app.
- Stack: Flutter app, Firebase backend and database (section 11).
- Pickup areas: Kimihurura, Kacyiru, Remera, Nyarutarama, Kicukiro, Gacuriro [Mock].

## 2. User types

Each person has one account with one role. Someone who wants to both rent and own creates two accounts [Change: the mock already has one role per account, now confirmed]. A person with several accounts can **switch between them from the profile without logging out and in again** (section 8.2) [New].

| Role | What they do | Documents |
| --- | --- | --- |
| **Renter** | Searches cars, requests bookings, pays, picks up, returns, reviews. | At sign-up: driving licence (number, expiry, photo). |
| **Car owner** | Lists cars, approves or declines requests, hands over cars, inspects returns, claims caution fees, tracks finances. | At sign-up: National ID (number, photo). Per car, at listing: plate; **insurance document and medical inspection certificate (both required)**; and the "yellow paper" (vehicle registration), which is **optional**. Each document is a photo plus number and expiry date [Change: the mock asked for the plate at sign-up]. |

Both roles: name, email, date of birth (18+) and a phone number, entered at sign-up and editable later in profile settings. Sign-in is email and password, or Google. Each account needs its own email, so someone with both roles uses two different emails. Anyone who completes sign-up is treated as verified; verification is simulated [Mock]. Users can browse without verification [New].

## 3. Glossary

- **Rental fee**: daily rate × number of days. The daily rate is the car's base daily price, or a lower **long-rental rate** if the owner set one for that length of rental (section 6.2).
- **Long-rental rate** [New]: a discounted daily price the owner sets for rentals of N days or more. Example: base 100,000 per day, 80,000 per day from 3 days, 75,000 per day from 5 days. The lower rate applies to **every day** of the rental.
- **Platform fee**: Veloce's fee, a flat RWF 2,000 per booking, **paid by the owner** and taken from the owner's payout [Change: the mock charges it to the renter].
- **Caution fee**: refundable security deposit, set per car by the owner. Paid by the renter with the rental fee and held by Veloce.
- **Held**: money Veloce has collected but not yet released.
- **Claim**: the owner's request to keep an amount, up to the caution fee, because of damage or an issue.
- **Late fee**: extra charge for returning late: **30% for each late day, compounding on the running total** (a 100,000 rental becomes 130,000 after one late day, 169,000 after two, about 219,700 after three; the late fee is the amount above the original rental fee). A part day counts as a full late day. Charged by default; the owner can waive or reduce it by agreement with the renter.
- **Days convention [Mock]**: rental days = days from pickup date to return date; the return day is not charged.
- **Booking reference [Mock]**: `VLC-####`.

---

## 4. End-to-end flow

### 4.1 Happy path

1. **Search** [Mock]. The renter picks area and dates, applies filters and sees cars that are published and free for the whole range, **within the owner's availability window** [Change, section 6.3].
2. **Request** [Mock + Change]. The renter opens a car, picks dates, and sees: rental fee, caution fee, **total payable**. There is no platform fee line, because the owner pays it. The renter accepts the terms and sends the request. No money moves. Status: *Pending*.
3. **Owner decision** [Mock]. The owner reviews the renter's profile (name, rating, past rentals and reviews, first-time flag; no contact details, see 4.4), ticks "I reviewed their info" and approves or declines (decline needs a reason). A request that gets no answer within **24 hours** expires [New].
4. **On approval** [Change]:
    - The owner's other pending requests **with overlapping dates** for that car are declined automatically with the reason that the car has been booked.
    - **All of the renter's other open requests** (pending or approved) are cancelled automatically.
    - The booking's dates are blocked for the car.
5. **Payment** [Mock + Change]. The renter pays rental fee + caution fee by MoMo. The deadline is **24 hours after approval, and never later than the pickup date** (if the request is approved on the pickup day itself, payment is due before handover); otherwise the booking expires and the car is released. Veloce holds the full amount. Status: *Confirmed*. **Payment is what unlocks contact details**: the other side's phone number and email, and the exact meeting point, are revealed to both sides at this moment [New].
6. **Agreement** [Mock]. The renter acknowledges the rental agreement.
7. **Pickup** [Mock + Change]. At handover both sides complete the pickup checklist, **attaching photos (required) and optionally video** [Change]. **Both the owner and the renter must confirm pickup** [Change; the mock needs only the owner]. When both have confirmed, the status becomes *Active* and the **rental fee is released to the owner's MoMo** minus the RWF 2,000 platform fee (for a 50,000 rental with a 25,000 caution fee, the owner receives 48,000 at pickup). The caution fee stays held until the return. Until both have confirmed, nothing is released; if one side never confirms, the money stays held until either side cancels (4.4).
8. **Return** [Mock + Change]. At return both sides complete the return checklist with photos (required) and video (optional). Both must confirm the return. A return after the agreed return date accrues the late fee (glossary) for each late day until the return is confirmed. The late fee and any claim together cannot exceed the caution fee; anything beyond that is settled outside the app.
9. **Caution settlement**
    - **No problem** [Mock]. The owner confirms no issue; both sides confirm the return and the caution outcome, and the caution fee is refunded to the renter.
    - **Problem** [Mock + Change]. The owner claims **any amount up to the caution fee**, with a written reason and evidence photos. The renter agrees or does not agree. If the renter agrees, the claimed amount goes to the owner and any remainder is refunded to the renter. If the renter does not agree, the caution fee stays held while the two talk outside the app. **There is no deadline and no admin.** The owner can then claim again at the same amount (a new reason or evidence is allowed) or at a lower amount, as often as they like, but never above the original claim; or the owner can refund the caution fee. The renter can only agree or not agree each time. There is no chat, so they talk outside the app.
10. **Reviews** [Change]. Both sides must review each other, and the renter also reviews the car (section 8.3). Reviews are public and can be edited, not removed.

If the damage costs more than the caution fee, the two parties settle the difference themselves, outside the app. The owner can still log the repair cost in the app for their own finances (section 7).

### 4.2 Booking states

| State | Label (renter / owner) | Entered when | Leaves when |
| --- | --- | --- | --- |
| `pending` | Pending approval / Needs your decision | Renter sends request | Owner approves or declines; renter cancels; 24h expiry; auto-decline |
| `approved` | Approved · payment required / Awaiting payment | Owner approves | Renter pays; either side cancels; payment deadline passes |
| `confirmed` | Confirmed | Payment succeeds | Both sides confirm pickup; either side cancels (full refund) |
| `active` | Active rental | Both confirmed pickup | Return stage starts |
| `return` | Return inspection | A side starts the return | Both confirm return, then owner settles caution |
| `review` | Caution fee claim | Owner claims an amount | Renter agrees; or owner claims again (same or lower amount) or refunds; open until settled |
| `completed` | Completed | Caution fully settled | Terminal (reviews still due) |
| `declined` | Declined | Owner declines or auto-decline | Terminal |
| `cancelled` | Cancelled | Cancelled by a side or automatically | Terminal |
| `expired` [New] | Expired | No owner reply in 24h, or no payment by deadline | Terminal |

Within `confirmed` and `return`, each side's confirmation is tracked separately (for example "Waiting for the owner to confirm pickup").

### 4.3 Money flow

| Event | Rental fee | Platform fee (RWF 2,000) | Caution fee |
| --- | --- | --- | --- |
| Renter pays [Change] | Held | Not charged to renter | Held |
| Both confirm pickup | **Released to owner's MoMo, minus the platform fee** | Taken from the owner's payout | Held |
| Safe return | (with owner) | (taken) | **Refunded to renter** |
| Claim agreed | (with owner) | (taken) | **Claimed amount to owner, remainder to renter** |
| Claim not agreed | (with owner) | (taken) | Held until agreed, or until the owner claims again at the same or a lower amount, or refunds |
| Late return | n/a | n/a | Late fee (30% per late day, compounding) is part of the settlement, capped by the caution fee |
| Cancelled before both confirm pickup | Refunded | none taken | Refunded |
| Expired (no payment) | nothing paid | none | nothing paid |

### 4.4 Automatic rules

- **Competing requests**: approving a request declines the car's other pending requests **whose dates overlap** [Change]. Non-overlapping requests stay pending.
- **Renter's other requests**: approving one of a renter's requests cancels **all** their other pending and approved requests, with the reason shown to the owners involved [Change; the mock did this at pickup]. If the renter then fails to pay in time, the booking expires and they must request again.
- **No extension, no shortening** once a booking is confirmed [New]. A renter who needs more time returns the car and makes a separate request later.
- **Expiry**: pending requests 24h; approved bookings until the payment deadline.
- **One booking at a time**: a renter with an approved, confirmed or active booking cannot send new requests [Mock].
- **Calendar blocking** [Mock]: an approved booking blocks its dates for the car.
- **Information and contact visibility** [New]: renter and owner can see each other's profile information at every stage: name, photo, rating, reviews, past rentals, first-time flag, and (for the owner) their cars. **Contact information is locked**: phone number and email (and the exact meeting point) stay hidden, shown as a locked placeholder, through request, approval and until the renter has **paid after the owner approved**. Payment unlocks them for both sides. They stay visible until the booking and any claim are closed. If the request is declined, cancelled or expires before payment, they are never revealed. Identity documents (National ID, licence) and the owner's payout MoMo number are never shown to the other side.
- **Cancellation**: either side can cancel at any time **until both have confirmed pickup**, with no penalty. The renter gets everything back (rental fee and caution fee) and no platform fee is taken. After both confirm pickup there is no cancellation.

---

## 5. Renter features

### 5.1 Account and onboarding [Mock]

- Welcome screen, create account, log in (email and password).
- Sign-up steps: choose role → details (name, phone, email, password, date of birth, licence number, expiry, photo) → simulated verification (with a failure state to retry) → welcome.

### 5.2 Search and filter [Mock]

- Home: greeting, search card (area, dates), type chips (All, Sedan, SUV, Hatchback), car cards, Explore and Saved tabs, "how it works".
- Area: "Anywhere in Kigali" or one of six neighbourhoods. Dates: calendar picker, past days disabled.
- A car is returned only if the whole range is inside the owner's availability window and free of bookings [Change].
- Filters: price min and max per day, type, transmission, seats (Any, 5+, 7+); active-filter count; reset.
- Results screen with count and empty state. Favourites ("Saved").
- Car card: photo, name and year, base daily price, transmission · seats · type, owner rating, area, availability.

### 5.3 Car detail [Mock]

- Photo carousel and a media screen (all photos, walkaround video). Specs, features, description.
- Owner block with name, rating and other profile information (contact details locked until payment, see 4.4), and the car's reviews screen [Change: reviews of the car, section 8.3].
- Rules (self-drive, fuel rule, smoking, extras) and a downloadable rental instructions PDF.
- Calendar showing unavailable days; the owner's availability window limits what can be selected; live price breakdown (rental fee, caution fee, total). When the car has long-rental rates, the car page shows a short note such as "3+ days: RWF 80,000 per day" and the breakdown line shows the rate applied, for example "RWF 80,000 × 3 days (long-rental rate)".
- Terms checkbox required before "Request booking". An owner viewing their own car sees a read-only preview.

### 5.4 Requesting [Mock + Change]

- Review screen: car, owner, dates, days, area, price breakdown without platform fee, terms checkbox, PDF.
- Confirmation screen with reference and "Pending approval".
- A renter may hold several open requests at once; the first one an owner approves cancels the rest (4.4).

### 5.5 Paying [Mock + Change]

- Available only after approval, before the deadline shown on the booking.
- MoMo only: enter a 9-digit number, pay the total (rental fee + caution fee). Simulated processing, success with transaction reference, failure with retry. Money is held until pickup is confirmed by both sides.

### 5.6 Managing a booking [Mock + Change]

- **My Activity**: Open (action required, pending), Active, Past; cards with quick actions.
- **Booking detail**: reference, status, plain-language headline, six-step timeline (Request, Approved, Paid, Handover, Return, Done), car, dates, owner, price rows, payment status, caution status, agreement status, contact details (locked, with a "Unlocked when you pay" hint, until payment succeeds).
- **Rental agreement**: nine sections; the renter acknowledges it before pickup. The late-return section states the 30%-per-day late fee; the cancellation section states that either side can cancel until both confirm pickup, with a full refund.
- **Pickup and return checklists**: five items each, **with required photos and optional video**, for both sides [Change].
- **Confirm pickup / confirm return**: each side confirms separately and sees whether the other has [Change].
- **Cancel**: allowed until both sides confirm pickup, full refund of everything paid.
- **Caution claim**: the renter sees the amount, reason and photos, and agrees or does not agree.
- **Payment history** [New]: a list of every money event for the renter (payment, caution refund, claim deduction, late fee, cancellation refund) with date, booking, amount and status. No export.

### 5.7 Reviews [Change]

The renter must review the owner (experience rating plus a written comment) and the car (rating plus comment) after completion. Both reviews are mandatory.

---

## 6. Car owner features

### 6.1 Account and onboarding [Mock + Change]

- Sign-up: name, phone, email, password, date of birth, National ID number and photo. The plate moves to the car listing.
- Payout method: a single MTN MoMo number, required before the first payout. No Airtel or bank option [Change].

### 6.2 Listing a car [Mock + Change]

Seven-step wizard with progress bar and per-step validation:

1. **Media**: at least 3 photos, up to 6, primary photo choosable; optional video.
2. **Vehicle details**: plate (Rwandan format `RAB 123 A`), make, model, year (2005–2026), type (Sedan, SUV, Hatchback, Minivan, Pickup), pickup neighbourhood, description.
3. **Specifications**: transmission, fuel, seats, features.
4. **Pricing**: daily price (minimum RWF 5,000), caution fee (0 allowed), and optional **long-rental rates** [New]: up to 3 tiers, each "from N days → price per day". Rules: N is 2 or more; each tier's price is lower than the base price and lower than any tier with fewer days; minimum RWF 5,000 per day; tiers can be edited or removed later and only affect new requests. The owner sees a live example for each tier (for instance "5 days: 5 × 75,000 = 375,000"). The three-day preview shows what the renter pays (rental fee, caution fee, total) and what the owner receives (rental fee minus RWF 2,000) [Change].
5. **Rental rules**: fuel rule, smoking policy, extras, optional rules PDF.
6. **Documents** [New]: three documents, each as a photo plus number and expiry date, simulated-verified:
    - **Insurance document**: required.
    - **Medical inspection certificate**: required [New].
    - **Yellow paper** (vehicle registration): **optional**. The owner can skip it at listing and add it later from the car's edit screen. If added, its photo, number and expiry date are all required.

    The plate on every document provided must match the listing. A car whose **insurance or medical inspection certificate has expired** is paused automatically and takes no new requests until the document is updated; bookings already confirmed continue. A missing or expired yellow paper does not pause the car.

7. **Review and publish**: the summary shows the documents provided; the yellow paper appears as "Not added" when skipped.

### 6.3 Availability [Change]

The owner sets **one date range** during which the car is available; renters can only book inside it. This replaces the mock's day-by-day blocking: there is a single range, no multiple ranges and no single-day blocking. There is no separate minimum or maximum rental length; the range is the limit. Days covered by approved bookings are locked inside the range.

### 6.4 Managing cars [Mock]

- My cars: photo, name, plate, daily price, status (Published or Paused), availability line, next rental, edit, availability, pause or resume, remove.
- Remove is blocked while the car has pending, approved, confirmed, active, return or claim-stage bookings.
- Paused cars are hidden from search.

### 6.5 Handling requests [Mock + Change]

- **My Activity** with Open (action required), Active, Past; grouped view when several requests target one car.
- **Request detail**: renter name, rating, past reviews, first-time flag (phone and email shown as locked until the renter pays), "You earn RWF X" (rental fee minus RWF 2,000), and the "I reviewed their info" tick before approving.
- **Decline**: reason required. **Approve**: triggers the automatic rules (4.4).
- **Pickup and return**: checklists with photos and optional video; both sides confirm.
- **Settle caution**: confirm no issue, or claim an amount with reason and photos (4.1 step 9). If the renter does not agree, the owner can claim again at the same or a lower amount (never above the original claim) or refund, repeating as needed while the claim is open. The overall cap is the caution fee paid.
- **Cancel**: allowed until both sides confirm pickup; no penalty; the renter is refunded in full.
- **Repair costs** [New]: after a return, the owner can add a repair or damage cost to the booking (amount, description, receipt photo) for Finances.

### 6.6 Dashboard [Mock + New]

Owner Home shows pending requests, car count, upcoming rentals, and a **Finances card** showing this month's total earned and total losses [Change: replaces the mock's single earnings figure]. Tapping it opens the Finances screen.

---

## 7. Finances (owner) [New]

Deliberately small: two numbers, two periods, and one view of the same data as either a chart or a transaction table.

### 7.1 The two figures

| Figure | Definition |
| --- | --- |
| **Total earned** | Rental fees released to the owner at pickup, minus the RWF 2,000 platform fee per booking, plus any late fees collected. |
| **Total losses** | For each booking with a repair or damage cost logged: repair cost minus the caution fee the owner received, when that is positive. Added up for the period. |

Caution fees received through agreed claims are not counted as earnings; they only reduce losses. Nothing else is shown: no upcoming money, caution held or refunded, net result or platform fee totals. The only list of money events is the transaction table (7.3), and it contains just the entries behind the two figures. Earnings are dated by the day the rental fee was released; losses by the day the repair cost was logged.

### 7.2 Periods

A two-way toggle: **This month** and **This year** (the current calendar month and year). No past periods, all-time or custom range.

### 7.3 Finances screen (all cars)

- Dashboard card: this month's earned and losses; tapping opens this screen.
- Period toggle (This month / This year).
- Two tiles: Total earned, Total losses.
- **View toggle: Chart / Table** [Mock]. Chart is the default. The toggle sits under the tiles, and the choice applies to both the all-cars and car screens. The period toggle drives whichever view is shown.
- **Chart view: earned and losses over time.** Month view: one pair of bars per day. Year view: one pair of bars per month (Jan to Dec). Earned and losses use two clearly different colours and a legend; tapping a bar shows its amounts. Months or days with no data show empty space.
- **Table view: transactions.** One row per entry in the selected period, newest first, with car, type (Earned or Loss), signed amount (+ earned, − loss) and date. Earned entries are the rental fee released at pickup net of the platform fee, and any late fee collected; loss entries are the loss from a logged repair cost (7.1). When the list is long, the screen shows only the latest 5 rows and a **View all transactions** link that opens a separate **Transactions page** with the full list for the selected period, the same toggle and a back button. If there are 5 rows or fewer, they all show inline and there is no link.
- **Per-car list**: each car with its earned and losses for the selected period, plus a small bar showing its share of total earnings. Tapping a car opens its Finances screen.

### 7.4 Car finances screen

Same period toggle, the same two tiles, the same Chart / Table toggle and the same Transactions page, filtered to that one car. Nothing else (no booking list).

### 7.5 Rules

- Every figure and every table row comes from the transaction ledger and the logged repair costs, not from booking status. The table total for a period equals the two tiles.
- Amounts in RWF, no decimals. No export (applies to the table too).
- Empty state when there is no data yet for the period, in both views.
- Repair costs are still logged per booking (amount, description, receipt photo); they feed Total losses.
- The gap between repair cost and caution is settled between owner and renter outside the app; Veloce only reports it.

---

## 8. Shared features

### 8.1 Notifications [Mock]

In-app only. List per role with icon by type, title, text, time, unread dot, mark all read, deep link to the booking, on/off setting. New events: request expired, payment deadline approaching, other party confirmed pickup or return, claim amount changed, late fee applied, review due.

### 8.2 Profile [Mock + Change]

Name, role, phone, email, identity status, edit profile, reviews received, payout MoMo number (owner), driving licence (renter: add or change, simulated verification), help and support, notifications switch, sign out. The profile gets an **About page** and a **Contact page**; Contact shows the support email, **r.kevin@alustudent.com**, which is how users reach support, since no-shows and non-returns are handled there.

**Account switcher** [Change: the mock has it as a prototype tool; it becomes a real feature]. A person with more than one account (for example one Renter and one Car owner account) can switch between them from the profile, without logging out and logging in again.

- The profile has an **Accounts** entry that lists every account linked on this device. Each row shows the name, the email and a **label for the account type: Renter or Car owner**. The account in use is marked as current, and its label also shows in the profile header.
- Tapping another account switches to it at once, with no password or Google prompt, and opens that account's Home. Tabs, My Activity, notifications, finances and every other screen then show that account's data only.
- **Add another account**: signs in once to another account (email and password, or Google) or creates a new one, and links it to this device. After that it can be switched to without signing in again.
- **Remove from this device** signs that account out and unlinks it; the account itself is untouched. **Sign out** signs out the account in use.
- Each account stays a separate account: its own email, one role, its own bookings, reviews and payout MoMo number. Nothing is shared or merged between them. Rules that depend on the account (one booking at a time, pending reviews) apply per account.
- Linked accounts are remembered on this device only. If a linked account's sign-in has expired or was revoked, switching to it asks for sign-in again.

### 8.3 Reviews [Change]

- **Both sides must review each other** after completion: the owner reviews the renter, the renter reviews the owner.
- The renter writes **two reviews, both mandatory**: one for the owner (experience stars plus a free-text comment) and one for the car (stars plus a comment).
- **The car has its own reviews**, written by renters and shown on the car page.
- A pending review blocks the user from sending new requests or approving new ones until it is done.
- Reviews are **public**, can be **edited**, and **cannot be removed**.
- Averages and counts show on cards and profiles, as in the mock.

### 8.4 Rental agreement [Mock]

Generated per booking from the car's rules. States the cancellation rule and the 30%-per-day late fee.

---

## 9. Data model (proposed)

| Entity | Key fields |
| --- | --- |
| **User** | id, role (renter or owner), name, email, auth provider (password or Google), phone, date of birth, verified, created |
| **Licence** (renter) | user, number, expiry, photo, active |
| **OwnerIdentity** | user, National ID number, photo |
| **PayoutMethod** | user, MoMo number |
| **Vehicle** | id, owner, plate, make, model, year, type, transmission, fuel, seats, features[], description, daily price, long-rental rates (up to 3: from days, price per day), caution fee, neighbourhood, fuel rule, smoking, extras[], rules file, video, status |
| **VehicleDocuments** | vehicle, insurance (photo, number, expiry; required), medical inspection certificate (photo, number, expiry; required), yellow paper (photo, number, expiry; optional) |
| **VehiclePhoto** | vehicle, url, order, isPrimary |
| **AvailabilityWindow** | vehicle, from date, to date (one per vehicle) |
| **Booking** | id, reference, vehicle, renter, owner, start, end, days, rental fee, caution fee, platform fee (owner-side), total payable, status, decline or cancel reason, payDeadline, expiresAt, agreementAcknowledged, ownerPickupConfirmedAt, renterPickupConfirmedAt, ownerReturnConfirmedAt, renterReturnConfirmedAt, lateFee, completedAt |
| **ChecklistEntry** | booking, kind (pickup or return), side (owner or renter), item, ticked, at |
| **ChecklistMedia** | booking, kind, side, photo or video url |
| **Transaction (ledger)** | id, booking, type (charge, hold, release to owner, platform fee, refund, claim deduction, late fee, payout), amount, from, to, reference, status, at |
| **CautionClaim** | booking, amount, reason, evidence, renter response, history of amounts |
| **RepairExpense** | booking, amount, description, receipt photo, date |
| **Review** | booking, author, subject (user or vehicle), stars, comment, created, edited |
| **Favourite** | user, vehicle |
| **Notification** | user, type, title, text, booking, read, created |

The list of accounts linked for switching (8.2) is kept on the device, not in the database, so it needs no entity here.

The entity-relationship diagram for this model is in `veloce-er-diagram.md`.

---

## 10. Business rules summary

1. Renter pays `daily rate × days` + caution fee, where the daily rate is the base price or the owner's long-rental rate for that number of days. The owner pays RWF 2,000 out of the rental fee at release. The rate and total are locked when the request is sent; later price changes do not affect existing requests or bookings.
2. A request is possible only inside the car's availability window and on days free of approved or later-stage bookings.
3. The owner must approve every booking, after the "reviewed renter info" tick.
4. Pending requests expire after 24h; payment is due within 24h of approval and before pickup.
5. Approval declines overlapping pending requests for the car and cancels all the renter's other open requests.
6. The rental fee is released only when both sides have confirmed pickup.
7. Both sides must confirm return. The caution fee is refunded on a safe return, or settled by agreement on a claim.
8. A claim is any amount up to the caution fee, with a reason and photos. No deadline, no admin; money stays held until agreed. After a refusal the owner may claim again at the same or a lower amount, never above the original claim.
9. Confirmed bookings cannot be extended or shortened.
10. Late returns compound 30% per late day on the running total (waivable by the owner); late fee plus claim never exceeds the caution fee.
11. Either side can cancel until both confirm pickup, with no penalty and a full refund to the renter.
12. Both sides must review after completion; reviews are public and editable, never removable. A pending review blocks new requests and approvals.
13. A car with open bookings cannot be removed. Plates use the Rwandan format; users are 18+; licences must not be expired. Every car needs an insurance document and a medical inspection certificate; the yellow paper is optional. A car whose insurance or medical inspection certificate has expired is paused.
14. No-shows and non-returns go to support and, if needed, the authorities, outside the app.
15. Renter and owner see each other's profile information throughout, but phone, email and exact meeting point are locked until the renter pays after approval; they are never revealed on a declined, cancelled or expired request.
16. One role per account. A person with several accounts can switch between them from the profile without signing in again; the accounts stay separate and share no data.

---

## 11. Technical approach

- **Client**: Flutter, English only, mobile.
- **Backend**: Firebase.
    - Authentication: email and password, plus Google sign-in. A first Google sign-in continues into role choice and the document steps.
    - Firestore: users, vehicles, bookings, ledger, claims, reviews, notifications.
    - Storage: car photos and videos, ID and licence photos, vehicle documents, checklist media, receipts.
    - Cloud Functions: every booking and money state transition, the ledger, automatic declines and cancellations on approval, scheduled expiry (24h pending, payment deadline), and late-fee calculation. Money and status must never be changed directly by the client; security rules enforce this.
    - Notifications: in-app only, driven by Firestore documents.
- **Account switching**: Firebase Auth normally keeps one active user per app instance, so the client has to keep each linked account's sign-in on the device (in secure storage) and swap the active one when the user switches. The mechanism is an implementation choice; the behaviour is fixed in 8.2. Every request still runs as the active account, so security rules see one user at a time, and nothing about one account is readable from another.
- **Payments**: a MoMo adapter behind an interface, implemented as a simulation with success and failure modes (as in the mock). Escrow is a ledger with Veloce as the holder; the ledger must reconcile (money held = paid in − released − refunded).
- **Verification**: a simulated check at sign-up and on document upload, behind an interface.
- **Security**: ID and licence photos readable only by their owner and Veloce; contact details (phone, email, exact meeting point) revealed only after payment succeeds and kept visible until the booking and any claim are closed. Keep them in a private document that security rules let the two booking parties read only once the booking is `confirmed` or later, so the app cannot show them early by mistake.
- **Audit trail**: log actor, time and old/new state for every status change and money movement.

## 12. Out of scope

Admin panel; chat; push, SMS and email; export of statements; Airtel Money, banks and cards; languages other than English; cities other than Kigali; hourly or mileage pricing; chauffeur or delivery; extending or shortening a booking; in-app arbitration; coverage of damage above the caution fee; owner cancellation penalties; any Veloce role in insurance; multiple availability ranges; phone sign-in; one account holding both roles; merging or sharing data between a person's accounts.

---

## 13. Open questions

None at the moment. Every question from the first three rounds is answered and recorded in section 14.

---

## 14. Decisions made

| Topic | Decision |
| --- | --- |
| Rental fee | Held by Veloce; released when **both** sides confirm pickup |
| Platform fee | Flat RWF 2,000, paid by the owner |
| Payout | Straight to the owner's MoMo |
| Claims | Any amount up to the caution fee; renter agrees or not; no deadline; no admin; talk outside the app; after a refusal the owner can claim again at the same or a lower amount, never above the original claim |
| Damage above caution | Settled outside the app |
| Repair costs | Owner logs them with receipts for Finances |
| Competing requests | Decline only overlapping ones |
| Renter's other requests | Cancelled when the owner approves one |
| Pending expiry | 24 hours |
| Payment deadline | Earlier of 24 hours after approval and the pickup date |
| Cancellation | Either side, any time until both confirm pickup; full refund; no penalty |
| Unconfirmed pickup | Money stays held until someone cancels |
| Sign-in | Email and password, plus Google |
| Contact visibility | Each side sees the other's profile information throughout; phone, email and meeting point are locked until the renter pays after approval |
| Support | About and Contact pages in the profile; contact email r.kevin@alustudent.com |
| Phone number | Entered at sign-up, editable in profile settings |
| One booking at a time | A renter with an approved, confirmed or active booking cannot send new requests |
| Mandatory reviews | A pending review blocks new requests and approvals |
| Insurance | Entirely the owner's responsibility; Veloce takes no part |
| Late return | 30% per late day, compounding on the running total; owner may waive; with claims capped by the caution fee |
| Extension | None: no extending or shortening |
| Rental length | Set by the owner through a single availability date range |
| No-show, non-return | Support, then authorities, outside the app |
| Checklists | Photos required, video optional, both sides |
| Confirmations | Both sides confirm pickup, return and caution outcome |
| Finances | Only two figures (total earned, total losses), two periods (this month, this year), per-car view. Shown as a chart or a transaction table (Chart / Table toggle); the table shows the latest 5 rows with a link to a full Transactions page. No export |
| Renter payments | Payment history screen, no export |
| Reviews | Both ways, required, public, editable, not removable; cars have reviews |
| Accounts | One role per account; two accounts for both. A person with several accounts switches between them from the profile without logging out; each account is labelled Renter or Car owner; accounts stay separate |
| Verification | Owner: National ID at sign-up; per car: plate, insurance and medical inspection certificate (both required), yellow paper (optional). Renter: driving licence. Car papers carry number and expiry; plate must match; expired insurance or medical inspection certificate pauses the car. Simulated; no browsing gate |
| Payments | MoMo only, simulated; Veloce holds funds (licence assumed) |
| Admin | None |
| Notifications | In-app only |
| Language, city | English, Kigali only |
| Stack | Flutter + Firebase |

## 15. Differences between the mock and the decisions

| Area | Mock | Decision | Change needed |
| --- | --- | --- | --- |
| Platform fee | Added to the renter's total | Paid by the owner | Remove from renter breakdown; show in owner earnings and preview |
| Rental fee release | "Sent to owner" at payment | Released when both confirm pickup | Hold funds; two-sided confirmation |
| Pickup confirmation | Owner only | Both sides | Add renter confirmation |
| Return | Renter hands over, owner inspects | Both confirm | Add confirmations |
| Checklist evidence | Text ticks | Photos required, video optional | Add media upload |
| Competing requests | All pending declined | Overlapping only | Filter by dates |
| Renter's other requests | Cancelled at pickup | Cancelled at approval | Move trigger |
| Pending and payment timing | None | 24h expiry; pay before pickup | Add expiry and `expired` state |
| Caution claim | All of the fee; re-claim or refund on dispute | Any amount; talk outside; no deadline | Add amount; keep re-claim (same or lower amount only) and refund |
| Late return | Placeholder text | 30% per late day, compounding, waivable | Add compounding fee |
| Reviews | Owner rates renter, skippable | Both ways, required, public, editable; car reviews | New review flows |
| Payout and payment | MoMo, Airtel, bank | MoMo only | Remove Airtel and bank |
| Plate | Asked at owner sign-up | At car listing | Move to wizard |
| Car documents | None | Insurance and medical inspection certificate required; yellow paper optional | Add wizard step |
| Availability | Block single days | Availability window | Replace calendar behaviour |
| Finances | One earnings figure | Earned and losses only, month and year, per car, chart and transaction table (Chart / Table toggle, full list on its own page) | Build section 7; mock already has the toggle and table, add the 5-row preview and Transactions page |
| Payment history | None | Renter payment history | Add screen |
| Accounts switcher | Present as a prototype tool | Kept as a real feature: switch between linked accounts from the profile, each labelled Renter or Car owner | Keep it, add the account-type label, add "Add another account" and "Remove from this device", and replace the demo accounts with real linked ones |
| Claim dispute simulation buttons | Present | Remove (prototype only) | Remove |
| Sign-in | Email and password | Plus Google | Add Google sign-in |
| Availability | Single days blockable | One date range per car | Single range picker |
| Profile | Help FAQ | About and Contact pages | Add pages |
| Contact details | Shown at confirmation | Locked until payment; profile info always visible | Add locked state on request, approval and booking screens |
