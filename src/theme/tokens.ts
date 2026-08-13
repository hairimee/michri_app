/**
 * 디자인 토큰. 화면 코드에 색·간격 숫자를 직접 쓰지 않는다.
 *
 * 색 방향은 아직 확정 전이라(기획안 미결 항목) 차분한 청록–네이비 계열을 임시로 잡아뒀다.
 * 브랜드가 정해지면 이 파일의 값만 바꾸면 된다.
 */

const palette = {
  teal900: '#0F3F44',
  teal700: '#1B6B72',
  teal500: '#2A9099',
  teal100: '#DCEFF0',

  sand100: '#F6F3EE',
  sand200: '#EAE4DA',

  ink900: '#14181A',
  ink700: '#2C3438',
  ink500: '#5A666C',
  ink300: '#98A4AA',

  slate900: '#101416',
  slate800: '#181D20',
  slate700: '#242B2F',
  slate600: '#333C41',

  white: '#FFFFFF',
  red500: '#C0453B',
  amber500: '#C88A2E',
  green500: '#3F8A5B',
} as const;

export const Colors = {
  light: {
    background: palette.sand100,
    surface: palette.white,
    surfaceAlt: palette.sand200,
    border: '#E1DAD0',

    text: palette.ink900,
    textSecondary: palette.ink500,
    textMuted: palette.ink300,
    textOnAccent: palette.white,

    accent: palette.teal700,
    accentSoft: palette.teal100,

    danger: palette.red500,
    warning: palette.amber500,
    success: palette.green500,
  },
  dark: {
    background: palette.slate900,
    surface: palette.slate800,
    surfaceAlt: palette.slate700,
    border: palette.slate600,

    text: '#F2F4F4',
    textSecondary: '#A9B4B8',
    textMuted: '#6E7B80',
    textOnAccent: palette.white,

    accent: palette.teal500,
    accentSoft: palette.teal900,

    danger: '#E0685D',
    warning: '#E0AB55',
    success: '#5FAE7C',
  },
} as const;

export type ColorScheme = keyof typeof Colors;
export type ColorToken = keyof typeof Colors.light;

/** 4의 배수. 화면에서는 Spacing.md 처럼만 쓴다. */
export const Spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  xxl: 32,
  xxxl: 48,
} as const;

export const Radius = {
  sm: 6,
  md: 10,
  lg: 16,
  pill: 999,
} as const;

/** 기도제목·간증이 본문인 앱이라 본문 가독성 쪽에 무게를 뒀다. */
export const Typography = {
  display: { fontSize: 28, lineHeight: 36, fontWeight: '700' },
  title: { fontSize: 20, lineHeight: 28, fontWeight: '700' },
  subtitle: { fontSize: 17, lineHeight: 24, fontWeight: '600' },
  body: { fontSize: 16, lineHeight: 26, fontWeight: '400' },
  bodyStrong: { fontSize: 16, lineHeight: 26, fontWeight: '600' },
  caption: { fontSize: 13, lineHeight: 18, fontWeight: '400' },
  label: { fontSize: 12, lineHeight: 16, fontWeight: '600' },
} as const;

export type TypographyToken = keyof typeof Typography;
