import { StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ThemedText } from '@/components/themed-text';
import { Spacing } from '@/theme/tokens';
import { useTheme } from '@/theme/use-theme';

/**
 * M0 단계의 빈 화면. 각 탭이 어느 마일스톤에서 채워지는지 화면에 적어둔다.
 * 실제 화면이 들어오면 이 컴포넌트는 지운다.
 */
export function ScreenPlaceholder({
  title,
  description,
  milestone,
}: {
  title: string;
  description: string;
  milestone: string;
}) {
  const { colors } = useTheme();

  return (
    <SafeAreaView style={[styles.root, { backgroundColor: colors.background }]} edges={['bottom']}>
      <View style={styles.body}>
        <ThemedText variant="display">{title}</ThemedText>
        <ThemedText variant="body" color="textSecondary" style={styles.description}>
          {description}
        </ThemedText>
        <View style={[styles.badge, { backgroundColor: colors.accentSoft }]}>
          <ThemedText variant="label" color="accent">
            {milestone}
          </ThemedText>
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  body: { flex: 1, justifyContent: 'center', paddingHorizontal: Spacing.xl, gap: Spacing.md },
  description: { maxWidth: 420 },
  badge: {
    alignSelf: 'flex-start',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    borderRadius: 999,
  },
});
