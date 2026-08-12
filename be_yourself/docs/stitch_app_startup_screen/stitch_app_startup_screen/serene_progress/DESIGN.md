---
name: Serene Progress
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#414751'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#717783'
  outline-variant: '#c1c7d3'
  surface-tint: '#0060ac'
  primary: '#0060ac'
  on-primary: '#ffffff'
  primary-container: '#60a5fa'
  on-primary-container: '#003a6b'
  inverse-primary: '#a4c9ff'
  secondary: '#516072'
  on-secondary: '#ffffff'
  secondary-container: '#d2e1f7'
  on-secondary-container: '#556477'
  tertiary: '#5c5f61'
  on-tertiary: '#ffffff'
  tertiary-container: '#a0a3a5'
  on-tertiary-container: '#36393b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d4e3ff'
  primary-fixed-dim: '#a4c9ff'
  on-primary-fixed: '#001c39'
  on-primary-fixed-variant: '#004883'
  secondary-fixed: '#d4e4fa'
  secondary-fixed-dim: '#b9c8de'
  on-secondary-fixed: '#0d1c2d'
  on-secondary-fixed-variant: '#39485a'
  tertiary-fixed: '#e0e3e5'
  tertiary-fixed-dim: '#c4c7c9'
  on-tertiary-fixed: '#191c1e'
  on-tertiary-fixed-variant: '#444749'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
typography:
  headline-xl:
    fontFamily: Geist
    fontSize: 40px
    fontWeight: '600'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-max: 1200px
  gutter: 24px
  margin-mobile: 20px
  margin-desktop: 40px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 48px
---

## Brand & Style

The brand personality is rooted in the concept of "The Gentle Return"—a non-judgmental, resilient approach to personal growth. This design system serves a target audience seeking clarity amidst digital noise, prioritizing mental well-being and consistent self-improvement. 

The visual style is **High-End Minimalism** mixed with **Soft Tonal Layers**. It avoids the aggressive "hustle" culture aesthetics in favor of a peaceful, focused environment. The UI utilizes generous whitespace to reduce cognitive load, allowing the user's content and progress to remain the primary focus. Every transition and layout choice should evoke a sense of quiet confidence and effortless momentum.

## Colors

The palette is centered around a breathable, airy light mode. 

- **Primary (#60a5fa):** A soft, inspiring blue used for primary actions, progress indicators, and active states. It represents clarity and the sky.
- **Secondary (#94a3b8):** A muted slate blue used for secondary text and decorative icons, providing a soft bridge between the primary color and the background.
- **Surface (#f8fafc):** A very light cool gray used for cards and container backgrounds to subtly distinguish them from the pure white base.
- **Neutral (#1e293b):** A deep charcoal, never pure black, used for maximum legibility in typography while maintaining a soft, premium feel.

## Typography

This design system utilizes **Geist** for its technical precision and modern, airy feel. The typographic hierarchy is designed to be understated.

Headlines use tighter letter-spacing and medium-to-semibold weights to create a sophisticated, editorial look. Body text is prioritized for legibility with ample line height to ensure a comfortable reading experience during long reflection sessions. Labels are occasionally capitalized with slight tracking to provide a clear distinction for utility-based text like category tags or small buttons.

## Layout & Spacing

The layout follows a **Fluid Grid** model that transitions into a centered **Fixed Grid** on larger viewports.

- **Desktop:** A 12-column grid with 24px gutters. Content is centered with a max-width of 1200px to prevent eye strain.
- **Mobile:** A single-column flow with 20px side margins.
- **Rhythm:** We use an 8px baseline grid. Spacing between major sections (Stack-LG) should be aggressive to maintain the "calm" atmosphere, giving elements room to breathe. Components should use Stack-SM for internal grouping and Stack-MD for separating distinct functional areas.

## Elevation & Depth

Depth is achieved through **Ambient Shadows** and **Tonal Layering** rather than harsh borders.

- **Base Layer:** Pure White (#ffffff).
- **Surface Layer:** Use the Tertiary color (#f8fafc) for cards and secondary containers to create a soft "inset" or "raised" look without high contrast.
- **Shadows:** Use extremely soft, diffused shadows (Blur: 20px-40px) with a low-opacity primary tint (e.g., `rgba(96, 165, 250, 0.08)`) to make elements feel like they are floating on a cloud of light.
- **Interaction:** On hover or active states, elevation should increase slightly by deepening the shadow blur, never by changing the border thickness.

## Shapes

The shape language is **Rounded**, reflecting a friendly and organic personality. 

Standard components (inputs, small cards) use a 0.5rem radius. Larger containers, such as modal sheets or main content cards, should use the `rounded-xl` (1.5rem) setting to feel more like physical, tactile objects. Interactive elements like buttons should never have sharp corners, as rounder shapes are perceived as more approachable and less "clinical."

## Components

- **Buttons:** Primary buttons use a solid Soft Blue fill with white text. Secondary buttons use a Tertiary background with Primary colored text. Avoid heavy borders; use subtle shadows to define depth.
- **Cards:** Cards should have no borders. Use the Tertiary background color or a very soft shadow against the White background.
- **Input Fields:** Use a subtle Tertiary fill. On focus, the background turns White and a 2px Soft Blue soft-glow (shadow) appears.
- **Chips/Tags:** Small, pill-shaped elements with a light Primary tint background (10% opacity) and Primary colored text.
- **Lists:** Use generous vertical padding (16px+) between list items. Use thin, low-contrast separators (#f1f5f9) or simply whitespace to define rows.
- **Progress Bars:** Use a thick (8px) track in Tertiary and a rounded Primary fill to visualize growth in a soft, non-intimidating way.
- **Daily Reflection Cards:** A specialized component with a slight gradient (Primary to White) at 5% opacity to highlight "Thought of the Day" sections.