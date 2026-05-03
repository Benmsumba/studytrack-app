# Accessibility (a11y) Improvement Plan for StudyTrack

## Current Status Assessment

### Accessibility Checklist
- ❌ Semantic labels on form fields (Login/Signup)
- ❌ Semantic descriptions on icon buttons
- ❌ Color contrast verification (especially light theme)
- ✅ Minimum tap target size (Material Design 3 defaults to 48dp)
- ❌ Focus navigation testing
- ❌ Screen reader support review
- ❌ Keyboard navigation support
- ❌ Alt text for images

## Priority 1: Form Fields & Labels (High Priority)

### Issue
Form fields in auth screens lack proper semantic labels for screen readers.

### Screens to Update
1. `lib/features/auth/screens/login_screen.dart`
2. `lib/features/auth/screens/signup_screen.dart`

### Implementation Pattern
```dart
// BEFORE
TextField(
  controller: _emailController,
  decoration: InputDecoration(
    labelText: 'Email Address',
    hintText: 'Enter your email',
  ),
)

// AFTER
Semantics(
  label: 'Email Address',
  textField: true,
  enabled: true,
  onTap: () => _emailFocus.requestFocus(),
  child: TextField(
    focusNode: _emailFocus,
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: InputDecoration(
      labelText: 'Email Address',
      hintText: 'Enter your email',
      helperText: 'example@domain.com',  // Add helper for clarity
      floatingLabelBehavior: FloatingLabelBehavior.always,  // Better a11y
    ),
  ),
)
```

### Form Field Best Practices
- Always include `labelText` (required by Material Design)
- Add `helperText` for format hints
- Use `floatingLabelBehavior: FloatingLabelBehavior.always`
- Wrap in `Semantics` with `textField: true`
- Use `errorText` (not just error styling) for validation

---

## Priority 2: Icon Button Labels (High Priority)

### Issue
Icon-only buttons lack semantic description for screen readers.

### Update Pattern
```dart
// BEFORE
IconButton(
  icon: const Icon(Icons.visibility),
  onPressed: _togglePasswordVisibility,
)

// AFTER
Semantics(
  button: true,
  label: _showPassword ? 'Hide password' : 'Show password',
  enabled: true,
  onTap: _togglePasswordVisibility,
  child: IconButton(
    icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
    onPressed: _togglePasswordVisibility,
    tooltip: _showPassword ? 'Hide password' : 'Show password',
  ),
)
```

### Affected Areas
- Password visibility toggles (all auth screens)
- Navigation buttons in main_shell.dart
- Menu icons in app bars
- Action buttons in bottom sheets

---

## Priority 3: Color Contrast Verification (Medium Priority)

### Issue
Some color combinations may fail WCAG AA/AAA standards.

### Current Concerns
- Dark text on dark background (light theme labels on violet)
- Cyan secondary text on dark backgrounds
- Border colors vs background

### Recommended Actions
1. Check contrast ratios using WCAG checker
2. Adjust palette if needed:
   - Text on neonViolet: ensure 4.5:1 contrast
   - Text on neonCyan: ensure 4.5:1 contrast
   - Borders on dark: ensure sufficient visibility

### WCAG Standards
- **AA Level**: 4.5:1 for normal text, 3:1 for large text
- **AAA Level**: 7:1 for normal text, 4.5:1 for large text

---

## Priority 4: Keyboard Navigation (Medium Priority)

### Issue
Users may not be able to navigate using keyboard only.

### Implementation
```dart
// Ensure proper focus order by using FocusTraversalOrder
FocusTraversalGroup(
  policy: NumericFocusOrder(),
  child: Column(
    children: [
      FocusTraversalOrder(order: const NumericFocusOrder(1), child: ...),
      FocusTraversalOrder(order: const NumericFocusOrder(2), child: ...),
      FocusTraversalOrder(order: const NumericFocusOrder(3), child: ...),
    ],
  ),
)

// For text fields, use onEditingComplete to move focus
TextField(
  onEditingComplete: () => FocusScope.of(context).nextFocus(),
)
```

### Fields Requiring Focus Management
- Login screen: email → password → forgot password link → sign up link → login button  
- Signup screen: full name → email → password → confirm password → terms → signup button
- Onboarding screens: all form fields

---

## Priority 5: Semantic Descriptions (Medium Priority)

### Issue
Custom widgets lack semantic information for assistive technologies.

### Implementation Example
```dart
// Custom stat card
Semantics(
  label: 'Topics Mastered',
  enabled: true,
  child: GlassCard(
    child: Column(
      children: [
        Icon(Icons.school_rounded),
        Text('_topicsMastered'),  // Value should be announced
        Text('Topics Mastered'),
      ],
    ),
  ),
)

// Carousel/PageView
Semantics(
  slider: true,
  label: 'Weekly Report Page ${currentPage} of ${totalPages}',
  onIncrease: () => _pageController.nextPage(...),
  onDecrease: () => _pageController.previousPage(...),
  child: PageView(children: [...]),
)
```

---

## Priority 6: Screen Reader Testing (Low Priority - QA Phase)

### Testing Approach
1. Enable TalkBack (Android) / VoiceOver (iOS) in accessibility settings
2. Test critical paths:
   - Login flow
   - Signup flow
   - Navigation between main screens
   - Module/topic selection
   - Study group interaction
3. Verify:
   - All buttons have descriptive labels
   - Form field labels are read correctly
   - Errors are announced
   - Loading states are announced
   - Dynamic content updates are announced

---

## Implementation Roadmap

### Phase 1: Auth Screens (This Sprint)
- [ ] Add semantic labels to login form fields
- [ ] Add semantic labels to signup form fields
- [ ] Add password visibility toggle labels
- [ ] Test keyboard navigation on auth screens
- [ ] Review color contrast on text inputs

**Estimated Time**: 3-4 hours

### Phase 2: Core UI Components (Next Sprint)  
- [ ] Update icon buttons throughout app
- [ ] Add semantic descriptions to stat cards
- [ ] Ensure bottom navigation has proper labels
- [ ] Update custom widgets with semantics

**Estimated Time**: 4-5 hours

### Phase 3: Data Presentation Screens (Future Sprint)
- [ ] Add semantics to chart/data visualization widgets
- [ ] Ensure carousel/PageView navigation is accessible
- [ ] Add alt text for custom graphics
- [ ] Test screen reader on complex screens

**Estimated Time**: 5-6 hours

### Phase 4: Testing & Refinement (Final Sprint)
- [ ] Run TalkBack/VoiceOver testing
- [ ] Test keyboard-only navigation
- [ ] Perform WCAG contrast analysis
- [ ] Document accessibility features

**Estimated Time**: 4-5 hours

---

## Code Example: Enhanced Login Screen

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late FocusNode _emailFocus;
  late FocusNode _passwordFocus;

  @override
  void initState() {
    super.initState();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedFocusTraversalPolicy(),
      child: Semantics(
        container: true,
        label: 'Login Screen',
        enabled: true,
        child: Column(
          children: [
            Semantics(
              label: 'Email Address',
              textField: true,
              enabled: true,
              child: TextField(
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  helperText: 'example@domain.com',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
              ),
            ),
            Semantics(
              label: 'Password',
              textField: true,
              enabled: true,
              obscured: true,
              child: TextField(
                focusNode: _passwordFocus,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  helperText: 'At least 8 characters',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Login',
              enabled: true,
              onTap: _handleLogin,
              child: ElevatedButton(
                onPressed: _handleLogin,
                child: Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Resources

### Flutter Accessibility
- [Flutter Semantics Documentation](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [Material Design Accessibility](https://material.io/design/usability/accessibility.html)

### WCAG Guidelines
- [WCAG 2.1 Contrast Minimum (AA)](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum)
- [WCAG 2.1 Focus Visible](https://www.w3.org/WAI/WCAG21/Understanding/focus-visible)

### Testing Tools
- **Android**: TalkBack screen reader
- **iOS**: VoiceOver screen reader
- **Desktop**: Semantic Debugger (`showSemanticsDebugger: true`)
- **Online**: WebAIM Contrast Checker

---

## Success Criteria

- ✅ All form fields have semantic labels
- ✅ All icon buttons have semantic descriptions or tooltips
- ✅ Color contrast meets WCAG AA minimum (4.5:1)
- ✅ Keyboard navigation works for all critical paths
- ✅ Screen reader announces key elements correctly
- ✅ Focus indicators are visible (default Flutter implementation)
- ✅ No elements are skipped by assistive technologies

---

## Status & Next Steps

**Created**: Current Sprint
**Priority**: Medium-High (impacts app store compliance and user inclusivity)
**Estimated Total Time**: 16-20 hours (phased approach)
**Target Completion**: 2-3 sprints

Next action: Start Phase 1 implementation on login/signup screens
