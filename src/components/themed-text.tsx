import { Text, type TextProps } from 'react-native';

import { Typography, type ColorToken, type TypographyToken } from '@/theme/tokens';
import { useTheme } from '@/theme/use-theme';

type Props = TextProps & {
  variant?: TypographyToken;
  color?: ColorToken;
};

export function ThemedText({ variant = 'body', color = 'text', style, ...rest }: Props) {
  const { colors } = useTheme();
  return <Text style={[Typography[variant] as never, { color: colors[color] }, style]} {...rest} />;
}
