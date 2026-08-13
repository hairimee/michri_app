import { View, type ViewProps } from 'react-native';

import type { ColorToken } from '@/theme/tokens';
import { useTheme } from '@/theme/use-theme';

type Props = ViewProps & { background?: ColorToken };

export function ThemedView({ background = 'background', style, ...rest }: Props) {
  const { colors } = useTheme();
  return <View style={[{ backgroundColor: colors[background] }, style]} {...rest} />;
}
