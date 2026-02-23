---
name: animation-patterns
description: Remotionで使える基本アニメーションパターン集
metadata:
  tags: remotion, animation, patterns
---

# アニメーションパターン集

## 基本ルール

**すべてのアニメーションは `useCurrentFrame()` で駆動する！**

```tsx
import { useCurrentFrame, useVideoConfig } from "remotion";

const MyComponent = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  // ...
};
```

## 禁止事項

- ❌ CSS transitions
- ❌ CSS animations
- ❌ Tailwindのアニメーションクラス（animate-*）
- ❌ setInterval / setTimeout
- ❌ Math.random()（毎フレーム変わる）

## フェードイン

```tsx
const opacity = interpolate(
  frame,
  [0, 30], // 0〜30フレーム
  [0, 1],  // 0〜1
  { extrapolateRight: "clamp" }
);

return <div style={{ opacity }}>Hello</div>;
```

## フェードアウト

```tsx
const opacity = interpolate(
  frame,
  [0, 30],
  [1, 0],
  { extrapolateRight: "clamp" }
);
```

## フェードイン＆アウト

```tsx
const opacity = interpolate(
  frame,
  [0, 30, 270, 300], // 0〜30でイン、270〜300でアウト
  [0, 1, 1, 0],
  { extrapolateRight: "clamp", extrapolateLeft: "clamp" }
);
```

## スケールアニメーション（spring）

```tsx
import { spring } from "remotion";

const scale = spring({
  frame,
  fps,
  config: { damping: 15, stiffness: 200 },
});

return <div style={{ transform: `scale(${scale})` }}>Hello</div>;
```

### springの設定

| 設定 | 効果 |
|------|------|
| `damping: 200` | バウンスなし、スムーズ |
| `damping: 10` | 大きくバウンス |
| `stiffness: 200` | 速い |
| `stiffness: 50` | ゆっくり |

## スライドイン（左から）

```tsx
const translateX = interpolate(
  frame,
  [0, 30],
  [-100, 0],
  { extrapolateRight: "clamp" }
);

return <div style={{ transform: `translateX(${translateX}px)` }}>Hello</div>;
```

## 1文字ずつ表示

```tsx
const AnimatedTextByChar: React.FC<{ text: string; delay?: number }> = ({ text, delay = 0 }) => {
  const frame = useCurrentFrame();

  return (
    <div style={{ display: "flex" }}>
      {text.split("").map((char, i) => {
        const charDelay = delay + i * 3;
        const opacity = interpolate(
          frame - charDelay,
          [0, 10],
          [0, 1],
          { extrapolateLeft: "clamp", extrapolateRight: "clamp" }
        );
        return (
          <span key={i} style={{ opacity }}>
            {char === " " ? "\u00A0" : char}
          </span>
        );
      })}
    </div>
  );
};
```

## シーケンス（シーン切り替え）

```tsx
import { Sequence } from "remotion";

return (
  <AbsoluteFill>
    {/* 0〜150フレーム：シーン1 */}
    <Sequence from={0} durationInFrames={150}>
      <Scene1 />
    </Sequence>

    {/* 150〜300フレーム：シーン2 */}
    <Sequence from={150} durationInFrames={150}>
      <Scene2 />
    </Sequence>
  </AbsoluteFill>
);
```

## 波アニメーション（SVG）

```tsx
const Wave: React.FC<{ width: number; height: number }> = ({ width, height }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const points = [];
  const numPoints = 100;

  for (let i = 0; i <= numPoints; i++) {
    const x = (i / numPoints) * width;
    const phase = (frame / fps) * Math.PI * 2;
    const y = height / 2 + Math.sin((i / numPoints) * Math.PI * 4 + phase) * (height / 3);
    points.push(`${x},${y}`);
  }

  return (
    <svg width={width} height={height}>
      <polyline
        points={points.join(" ")}
        fill="none"
        stroke="#64c8ff"
        strokeWidth={3}
      />
    </svg>
  );
};
```

## 回転アニメーション

```tsx
const rotation = interpolate(frame, [0, fps * 2], [0, 360]);
// または無限回転
const rotation = (frame / fps) * 360; // 1秒で1回転

return <div style={{ transform: `rotate(${rotation}deg)` }}>🌟</div>;
```

## 確率的な存在（点滅）

**Math.random()は使えないので、フレームベースで擬似ランダムを作る:**

```tsx
const flicker = (frame * 1733 + i * 17) % 100; // 擬似ランダム
const opacity = flicker > 30 ? 0.8 : 0.3;
```
