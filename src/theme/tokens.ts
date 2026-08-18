/**
 * 디자인 토큰. 화면 코드에 색·간격 숫자를 직접 쓰지 않는다.
 *
 * 브랜드 컬러 "종이와 잉크" —
 * 순백 직전의 찬 흰 바탕 + 청흑색 본문 + 잉크 파랑 강조.
 *
 * 바탕은 순백(#FFFFFF)이 아니다. 순백은 밝은 화면에서 눈이 부시고,
 * 그보다 밝은 색이 없어 카드·입력칸을 명도로 띄울 수 없다.
 *
 * 값은 OKLCH 로 설계하고 hex 로 옮겼다. React Native 의 StyleSheet 가
 * oklch() 를 파싱하지 못해서다. 주석의 oklch 값이 원본이니 색을 손볼 때는
 * hex 를 직접 만지지 말고 oklch 를 바꿔 다시 변환할 것.
 *
 * 잉크 색조 hue 258 로 통일했다. 종이·테두리만 hue 80 (따뜻한 쪽)에 남는다 —
 * 종이는 따뜻하고 잉크는 차갑다는 것이 이 팔레트의 전부다.
 *
 * 대비는 WCAG 2.1 로 검증했다. 본문 7:1, 보조 텍스트·강조색 4.5:1,
 * 흐린 텍스트 3:1 을 라이트·다크 양쪽에서 만족한다.
 */

const palette = {
  /* 잉크 파랑 — 강조색. 화면의 3% 를 넘기지 않는다 */
  blue700: '#1550A2', // oklch(44.5% 0.145 258) — light accent
  blue400: '#74A6EF', // oklch(72%   0.120 258) — dark accent
  blue100: '#DCE9FC', // oklch(93%   0.030 258) — light accent 배경
  blue900: '#183053', // oklch(31%   0.070 258) — dark accent 배경

  /* 종이 — 순백 직전의 찬 흰색. 잉크와 같은 hue 258 을 흔적만 남겼다 */
  paper000: '#FDFEFF', // oklch(99.6% 0.0015 258) — 카드 표면
  paper100: '#F8FAFC', // oklch(98.4% 0.0030 258) — 바탕
  paper200: '#EDEFF3', // oklch(95.2% 0.0060 258) — 눌린 표면·입력칸
  paper300: '#D5D9DF', // oklch(88.5% 0.0090 258) — 테두리

  /* 잉크 — 청흑색 본문 */
  ink900: '#111721', // oklch(20.5% 0.022 258)
  ink700: '#2B333F', // oklch(32%   0.024 258)
  ink500: '#5C6574', // oklch(50.5% 0.026 258)
  ink300: '#808A98', // oklch(63%   0.024 258)

  /* 다크 표면 — 잉크를 그대로 어둡게. 순흑 아님 */
  slate900: '#0D1117', // oklch(17.5% 0.014 258)
  slate800: '#171C23', // oklch(22.5% 0.016 258)
  slate700: '#252A33', // oklch(28.5% 0.018 258)
  slate600: '#353C46', // oklch(35.5% 0.020 258)

  inkOnBlue: '#0A1320', // oklch(18.5% 0.030 258) — 밝은 파랑 위 글자

  white: '#FFFFFF',
  red500: '#C0453B',
  amber500: '#C88A2E',
  green500: '#3F8A5B',
} as const;

export const Colors = {
  light: {
    background: palette.paper100,
    surface: palette.paper000,
    surfaceAlt: palette.paper200,
    border: palette.paper300,

    text: palette.ink900,
    textSecondary: palette.ink500,
    textMuted: palette.ink300,
    textOnAccent: palette.white, // 7.77:1

    accent: palette.blue700, // 종이 위 7.43:1
    accentSoft: palette.blue100,

    danger: palette.red500,
    warning: palette.amber500,
    success: palette.green500,
  },
  dark: {
    background: palette.slate900,
    surface: palette.slate800,
    surfaceAlt: palette.slate700,
    border: palette.slate600,

    text: '#E9EDF2', // oklch(94.5% 0.008 258)
    textSecondary: '#A4ABB6', // oklch(74% 0.018 258)
    textMuted: '#727985', // oklch(57.5% 0.020 258)
    // 다크의 강조색은 밝다. 흰 글자를 얹으면 2.49:1 로 깨져서 잉크를 얹는다
    textOnAccent: palette.inkOnBlue, // 7.49:1

    accent: palette.blue400, // 다크 바탕 위 7.61:1
    accentSoft: palette.blue900,

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
