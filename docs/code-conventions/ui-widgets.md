# UI and widgets

## Widget design

- Prefer small `StatelessWidget` classes over helper methods that return widgets. A class gets its own rebuild boundary, can be `const`, and can be tested.
- A `build` method reads top to bottom at one level of abstraction. Extract a widget when a subtree has a name or is reused. Do not nest more than a few levels.
- Pass only what a widget needs: values and callbacks, not whole Cubits or repositories. Widgets deep in the tree read state through `BlocBuilder` or `context.select`.
- Use `StatefulWidget` only for local, ephemeral UI state (controllers, focus, animation, a text field). Anything business-relevant belongs in a Cubit.
- Dispose every controller, focus node, animation and subscription in `dispose`.
- Mark constructors `const` and use `const` at call sites wherever possible. `prefer_const_constructors` is enforced.
- Give widgets `super.key`.

## Theming and reuse

- Colors, text styles, spacing and radii come from `Theme.of(context)` and the theme in `core/theme.dart`. No raw `Color(0xFF...)` or font sizes inside widgets.
- Spacing and sizes use named constants, not magic numbers sprinkled through layouts.
- Strings shown to users are not scattered as literals when they are reused or are labels of enums. Enum labels live on the enum, so a rename happens once.
- Shared generic widgets (loading, empty, error) are in `shared/widgets` and are used by every screen. Do not rebuild them per screen.

## Forms and validation

- Validators are pure functions in the feature's `domain` (or `core` if truly shared), unit tested, and used by `TextFormField.validator`.
- A form never decides rules inline. It calls the validator.
- Every text field has a placeholder. `hint` is a required parameter on `AppTextField`, `FormTextField` and `PasswordField`, and the shared texts (email, name, password, phone, ID numbers) live in `FieldHints` (`core/widgets`). Date and photo pickers show their own prompt ("Choose a date").
- Preserve user input on failure. Show field-level errors for validation and a snackbar or banner for network or server errors.
- Disable the submit button while submitting.

## Async and `BuildContext`

- Never use `BuildContext` after an `await` without checking `context.mounted`.
- Do not store `BuildContext` in a field.
- Navigation and snackbars triggered by state changes go through `BlocListener`, not inside Cubits.

## Navigation

- Plain `Navigator.push` for detail screens, and an auth gate at the root decides the first screen. Routes are opened through small functions or static `route()` helpers on the screen, not scattered `MaterialPageRoute` literals.
- A screen opened above the tab bar uses `PageAppBar` (`core/widgets`), not a bare `AppBar`. It shows the back button whenever the router can pop, including for the first page inside a `ShellRoute`, where `AppBar`'s own back button stays hidden. Tab roots keep a plain `AppBar`.
- Role-restricted screens check the role in the gate. The server rules remain the real enforcement.

## Performance

- Long lists use `ListView.builder` (or slivers), never a `Column` of children from a list.
- Keep `build` free of heavy work, sorting or filtering. Compute in the Cubit.
- Images: show the compressed network image with a placeholder and an error widget. Compress before upload, not after.
- Avoid rebuilding big subtrees on every state change: scope `BlocBuilder`, use `buildWhen`, `const` subtrees.

## Accessibility and layout

- Tap targets are at least 48 by 48 logical pixels. Icon buttons have tooltips or semantic labels.
- Respect text scaling. No fixed-height text containers that clip.
- Layouts must survive the Pixel 8 and smaller phones. Prefer `Flexible`, `Expanded` and scrolling over fixed sizes. Fix `RenderFlex overflowed` errors at the cause.
- Do not rely on color alone to convey status. Chips carry text.
