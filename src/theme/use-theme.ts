import { useColorScheme } from 'react-native';

import { Colors, type ColorScheme } from './tokens';

export function useTheme() {
  const scheme = useColorScheme();
  const name: ColorScheme = scheme === 'dark' ? 'dark' : 'light';
  return { scheme: name, colors: Colors[name] };
}
