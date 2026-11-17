# Test accounts

Dev project: `veloce-1fe08`.

**Password for every email account: `Veloce#2026`**

Sign in on the login screen with the email and the password. In debug builds, `/dev-login` also has
one-tap buttons for the accounts marked "Dev login".

| Role   | Email                        | Name                  | Dev login | Notes                              |
|--------|------------------------------|-----------------------|:---------:|------------------------------------|
| Renter | `renter1@veloce.test`        | Aline Uwase           |    Yes    | Approved booking, 3 favourites     |
| Renter | `renter2@veloce.test`        | Eric Mugisha          |    Yes    | Confirmed booking, disputed claim  |
| Renter | `renter3@veloce.test`        | Diane Ingabire        |    Yes    | Active booking                     |
| Renter | `renter4@veloce.test`        | Samuel Nshuti         |           | Pending request                    |
| Renter | `renter5@veloce.test`        | Clarisse Mukeshimana  |           | Email not verified                 |
| Renter | `renter6@veloce.test`        | Claudine Uwimana      |           |                                    |
| Renter | `renter7@veloce.test`        | Olivier Habineza      |           |                                    |
| Renter | `renter8@veloce.test`        | Beata Mukeshimana     |           |                                    |
| Renter | `renter9@veloce.test`        | Innocent Ndayisaba    |           |                                    |
| Renter | `renter10@veloce.test`       | Josiane Uwera         |           |                                    |
| Renter | `renter11@veloce.test`       | Thierry Bizimana      |           |                                    |
| Renter | `renter12@veloce.test`       | Emmanuel Kayitare     |           |                                    |
| Renter | `renter13@veloce.test`       | Jeanne Uwamahoro      |           |                                    |
| Renter | `renter14@veloce.test`       | Chantal Uwimana       |           |                                    |
| Renter | `renter15@veloce.test`       | Olivier Habineza      |           | Lock on a future confirmed booking |
| Renter | `p1-test-renter@veloce.test` | P1 Test Renter        |           | Made by hand, email not verified   |
| Owner  | `owner1@veloce.test`         | Patrick Habimana      |    Yes    | Cars 1–3                           |
| Owner  | `owner2@veloce.test`         | Grace Mukamana        |    Yes    | Cars 4–6                           |
| Owner  | `owner3@veloce.test`         | Jean Claude Niyonzima |    Yes    | Cars 7–8, car 8 paused             |
| Owner  | `owner4@veloce.test`         | Claudine Uwimana      |           |                                    |
| Owner  | `owner5@veloce.test`         | Olivier Kamanzi       |           |                                    |
| Owner  | `p6-owner@veloce.test`       | Frank Ndayisaba       |           |                                    |
| Google | `kevinrebakure@gmail.com`    | Kevin Rebakure        |           | Use "Continue with Google"         |

## Notes

- `npm run seed` in `tool/seed` resets the seeded accounts. `npm run reset` also deletes everything
  else. Tell the team first.
- Dev login has two switches, "MoMo payments succeed" and "Verification succeeds". Turn the second
  off to see the verification-failure screens.
- The phone code on the register step is shown in a SnackBar ("Demo code for …").
