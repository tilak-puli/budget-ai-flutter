# Neumorphism 2.0 Design Specification for Coin Master AI

## Overview

This specification outlines the implementation of a Neumorphism 2.0 design system for Coin Master AI, a personal finance application. The design aims to create a tactile, modern interface with soft shadows and highlights that give UI elements a subtle, physical quality.

![Neumorphism Example](https://miro.medium.com/v2/resize:fit:1400/1*Ls-4a2VHk10or0QkZNHGRA.jpeg)

## Design System Fundamentals

### Color Palette

**Light Mode**

- Primary Background: #EEEEEE (soft light gray)
- Secondary Background: #F5F5F5 (lighter gray for layering)
- Accent Color: #5271FF (blue)
- Secondary Accent: #83EAFF (light blue for highlights)
- Text Primary: #3A3A3A (dark gray)
- Text Secondary: #6F6F6F (medium gray)
- Shadow Light: #FFFFFF (white)
- Shadow Dark: #D1D9E6 (soft gray)

**Dark Mode**

- Primary Background: #2D2F3A (deep blue-gray)
- Secondary Background: #252734 (deeper blue-gray for layering)
- Accent Color: #6F88FF (light blue)
- Secondary Accent: #83EAFF (light blue for highlights)
- Text Primary: #E2E2E2 (off-white)
- Text Secondary: #A0A0A0 (light gray)
- Shadow Light: #35373F (lighter than background)
- Shadow Dark: #1A1C24 (darker than background)

### Typography

- Primary Font: SF Pro Display / Roboto (depending on platform)
- Headings: Medium/SemiBold, 20-28pt
- Subheadings: Medium, 16-18pt
- Body Text: Regular, 14-16pt
- Caption/Small Text: Regular, 12pt
- Numbers/Currency: Medium, with tabular figures

### Core Neumorphic Properties

- Base Depth: 4-6dp
- Border Radius: 15dp for cards, 12dp for buttons, 24dp for floating elements
- Shadow Spread: 3-5dp
- Light Source: Top-left (consistent across all elements)
- Intensity: 0.8 (for standard elements), 0.5-0.6 (for secondary elements)

## Component Specifications

### 1. Cards

**Expense Card**

- Height: Dynamic based on content
- Width: Match parent with 16dp horizontal margins
- Padding: 16dp all sides
- Corner Radius: 18dp
- Shadow Configuration:
  - Outer shadows: 2 shadows (one light, one dark) with offset based on light source
  - Depth: 5dp for standard state
- Content Layout:
  - Category displayed as a "pill" badge with neumorphic pressed effect
  - Amount displayed with prominent typography
  - Date with subtle, secondary text styling
  - Action buttons (edit/delete) as small circular neumorphic buttons

**Budget Status Card**

- Similar to expense card but with stronger depth (6dp)
- Contains progress indicator with neumorphic "track" and elevated "thumb"
- Category label and amount positioned with clear hierarchy

### 2. Buttons

**Primary Action Button**

- Size: 56dp diameter for circular buttons
- Depth: 5dp for unpressed state, -3dp for pressed state
- Animation: Smooth transition between states (150ms)
- Convex shape in resting state
- Interior shadow when pressed

**Text Input with Send Button**

- Input field: Slightly depressed neumorphic container (-2dp)
- Send button: Elevated neumorphic circle with accent color
- Microphone button: Same style as send button but with different icon
- Inactive state: Reduced depth and desaturated color

### 3. Navigation Elements

**Bottom Navigation**

- Subtle neumorphic effect with minimal depth (3dp)
- Selected item: Slightly depressed with accent color
- Unselected items: Slightly elevated with neutral color
- Animation: Smooth transition between states

**Tab Bar**

- Elevated container with internal depression for selected tab
- Selected tab appears "pressed in"
- Unselected tabs appear level with the bar

### 4. Charts and Data Visualization

**Pie/Donut Charts**

- Segments with subtle elevation differences (1-3dp)
- Central circle with stronger elevation (5dp)
- Shadow effects that emphasize segment boundaries

**Bar Charts**

- Bars with top surface highlights
- Subtle shadows between bars
- Axis lines with minimal inset appearance

### 5. Interaction States

**Touch Feedback**

- Pressed state: Element appears to sink in (-3dp to -5dp)
- Normal state: Element appears raised (3dp to 6dp)
- Disabled state: Flattened appearance with reduced shadows (1dp)
- Transition: Eased animation, 100-150ms duration

### 6. Special Elements

**Floating Action Button**

- Highest elevation in the interface (8dp)
- Strong highlight on top edge
- Deeper shadow underneath
- Press animation reduces elevation to 2dp

**Dialog Boxes**

- Appear to float above the interface (10dp)
- Soft outer shadow with higher blur radius
- Inner content may contain nested neumorphic elements

## Implementation Guidelines

### Shadow Technique

Use dual shadows for authentic neumorphism:

- One white/light shadow offset toward the light source
- One darker shadow offset away from the light source
- For inset elements (pressed buttons, text fields), invert these shadows

### Accessibility Concerns

- Maintain sufficient contrast between text and background (minimum 4.5:1)
- Ensure interactive elements have appropriate touch targets (minimum 44×44dp)
- Consider reduced shadow intensity option for users with visual sensitivity

### Performance Considerations

- Use optimized shadow rendering techniques to avoid performance issues
- Consider pre-rendering complex shadows for static elements
- Limit the number of nested neumorphic elements to prevent overdraw

## Animation Specifications

- Button Press: 100ms ease-in, 150ms ease-out
- Card Hover/Focus: 200ms ease-in-out
- Navigation Transitions: 250ms ease-in-out
- Progress Indicators: Smooth, continuous easing

## Flutter Implementation Approach

### Recommended Package

For implementation in Flutter, we recommend using either:

- `flutter_neumorphic` package (if actively maintained)
- Custom implementation using Flutter's `BoxDecoration` with multiple shadows

### Example Shadow Implementation

```dart
BoxDecoration(
  color: baseColor,
  borderRadius: BorderRadius.circular(15),
  boxShadow: [
    // Light shadow
    BoxShadow(
      color: lightShadowColor,
      offset: Offset(-3, -3),
      blurRadius: 5,
      spreadRadius: 1,
    ),
    // Dark shadow
    BoxShadow(
      color: darkShadowColor,
      offset: Offset(3, 3),
      blurRadius: 5,
      spreadRadius: 1,
    ),
  ],
)
```

### Pressed State Implementation

```dart
BoxDecoration(
  color: baseColor,
  borderRadius: BorderRadius.circular(15),
  boxShadow: [
    // Inner shadow effect
    BoxShadow(
      color: darkShadowColor,
      offset: Offset(-3, -3),
      blurRadius: 5,
      spreadRadius: 1,
      inset: true, // Note: inset is not directly supported in BoxShadow
    ),
    BoxShadow(
      color: lightShadowColor,
      offset: Offset(3, 3),
      blurRadius: 5,
      spreadRadius: 1,
      inset: true, // Custom implementation needed
    ),
  ],
)
```

## Key Screens to Redesign

1. **Home Screen**

   - Neumorphic cards for budget summary
   - Elevated quick action buttons
   - Tab navigation with pressed-effect indicators

2. **Expense Detail Screen**

   - Category badges with neumorphic effect
   - Expenditure chart with neumorphic segments
   - Action buttons with appropriate pressed states

3. **Add Expense Screen**

   - Form fields with inset appearance
   - Category selector with elevated options
   - Neumorphic submit button with strong depth

4. **Chat Interface**
   - Message bubbles with subtle elevation
   - Text input with inset field and elevated send button
   - AI response indicator with animated neumorphic effect

## Deliverables

The UI developer should deliver:

1. Themed components implementing the neumorphic style
2. Light and dark mode variants
3. Responsive layouts that maintain the neumorphic aesthetic across device sizes
4. Optimized implementation that maintains 60fps performance
5. Proper accessibility support including sufficient contrast and touch targets

## Design Examples

Add wireframes or mockups of key screens here once created.

## Timeline

- Design System Implementation: 1 week
- Core Components Development: 1 week
- Screen-by-Screen Implementation: 2 weeks
- Testing and Refinement: 1 week

## Resources

- [Neumorphism UI Design Guide](https://uxdesign.cc/neumorphism-in-user-interfaces-b47cef3bf3a6)
- [Flutter Neumorphic Package](https://pub.dev/packages/flutter_neumorphic)
- [Custom Shadows in Flutter](https://api.flutter.dev/flutter/painting/BoxShadow-class.html)
