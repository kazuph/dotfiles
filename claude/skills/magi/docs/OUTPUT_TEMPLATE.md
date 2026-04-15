# MAGI Output Template (Compact)

サブエージェントからメインセッションへの返却はこのテンプレートに従う。
**原則: 生ログは返さない。要点のみ返却し、詳細はファイル参照。**

```
## MAGI VERDICT

Goal: （40字以内で最終目的）
Verdict: （実行判断を1文で）
Confidence: High / Medium / Low

## PERSONA VOTES

| Persona | Recommendation | Confidence | Key Risk |
|---------|---------------|------------|----------|
| MELCHIOR (Claude) | A or B | High/Med/Low | 1行でリスク |
| BALTHASAR (Codex) | A or B | High/Med/Low | 1行でリスク |
| CASPER (Gemini) | A or B | High/Med/Low | 1行でリスク |

Consensus: （1行で合意点）
Conflict: （1行で対立点。なければ "None"）

## ACTION PLAN

1. [Action] – verify: [検証方法1行]
2. [Action] – verify: [検証方法1行]
3. [Action] – verify: [検証方法1行]

## RISKS

- [severity] [リスク内容] → [対策]

## BLOCKING QUESTIONS

- （追加確認が必要な点。最大2-3項目。なければ "None"）

## ARTIFACTS

Raw logs: `runtime/magi-<timestamp>-<persona>.log`
（詳細が必要な場合のみ上記ファイルを参照）

MAGI STATUS: DELIBERATION COMPLETE
```

## ガイドライン

- **Phase 1の生分析は返さない**: 各ペルソナの出力はファイルに保存し、PERSONA VOTESの1行サマリのみ返却
- **Phase 2の長文統合は返さない**: Consensus/Conflictは各1行に圧縮
- **Action Planは最大5ステップ**: 各ステップは1アクション + 1検証のみ
- **`raw_included: false` が原則**: 生ログはruntime/に保存、返却メッセージには含めない
- **全体で200トークン以内を目標**: メインセッションのコンテキストを汚染しない
