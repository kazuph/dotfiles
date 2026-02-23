# MAGI System Analysis: Gemini Function Calling問題

**実行日時**: 2026-01-24
**対象**: Gemini Side Panel Chrome拡張のFunction Calling問題
**MAGI Status**: ✓ DELIBERATION COMPLETE

---

## Situation Snapshot

- **Goal**: Gemini APIのFunction Calling問題を分析し、Function Callが確実に発火する実装方法を特定する
- **Constraints**: 現在のコードベース（gemini.ts, SidePanel.tsx等）を前提、Playwrightテスト13 passedの動作は維持
- **Success Metric**: Geminiが「クリックしました」とテキストで返すハルシネーションを防ぎ、Function Callを確実に返す実装を特定できること（Function Call発火率100%）

---

## PHASE 1: INDEPENDENT MULTI-PERSPECTIVE ANALYSIS

### 🔷 MELCHIOR-01 (Claude) - Comprehensive Reasoning
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: 倫理的配慮、長期保守性、ユーザー体験

**Actionable Insights:**

1. **System Promptから"Always confirm..."を削除し、2段階設計を導入** – **SidePanel.tsx + gemini.ts** – **ユーザーは操作の透明性を得つつ、ハルシネーションは発生しない（Function Call発火率100%、かつUI上で何が実行されたかが明示される）**
   - ツール実行直後にUI側で確認メッセージを表示
   - Function Calling自体は即座に発火させる

2. **`functionCallingConfig`を動的設定に** – **gemini.ts** – **ブラウザ操作モード時のみFunction Calling強制、通常会話時は自然な応答を維持（モード切替の明確な境界、誤発火ゼロ）**
   - browserActionModeがtrueの時のみ`AUTO`→`ANY`に切り替える
   - 通常会話時は`AUTO`を維持

3. **Tool定義のdescriptionに"IMPORTANT: Always use this function..."を追加** – **gemini.ts** – **System Prompt変更と相乗効果で、モデルがテキスト応答を選ぶケースが減少（測定: Function Call/Total比率の向上）**

### 🔶 BALTHASAR-02 (Codex/GPT-5) - Deep Research & Technical
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: Gemini API仕様、Function Calling技術詳細

**根本原因の発見:**
- GeminiのFunction CallingはデフォルトでAUTOモード（モデルが判断）
- これが「クリックした」とテキスト返答する主因

**Actionable Insights:**

1. **意図が明確な操作時に `functionCallingConfig` を `ANY` または `VALIDATED` に切替** – **gemini.ts / Backend** – **「ボタンをクリックして」入力で常に `functionCall` が返り、自然言語のみの返答が 0 件になる**
   - allowed_function_names を対象ツールに限定

2. **利用モデルがFunction Calling対応かを固定し明示** – **config / Backend** – **サポート表に載るモデルでのみ呼び出し、非対応モデル混入がゼロ**
   - 2.0 Flash-Liteは非対応であることを確認

3. **Tool定義を「強い型・明確な説明」に最適化し、System Promptに「行為を宣言せず必ずツール呼び出し」ルールを明示** – **gemini.ts / Prompt** – **誤ツール選択率の低下、ツール引数欠落が 0 になる**

**技術的根拠:**
- Gemini APIドキュメント: Function Callingはモード設定で挙動が大きく変わる
- `ANY`を使うとツール呼び出しを強制できる
- Function Calling対応モデルであることが前提

### 🔸 CASPER-03 (Gemini) - Pattern Recognition & Synthesis
**Status**: ✓ ANALYSIS COMPLETE | **Approach**: 自己分析、パターン認識

**根本原因の発見:**
- **System Prompt内の矛盾した指示**: "Always confirm what action you're about to take before executing it." がモデルに「まずテキストで宣言する」ことを優先させている
- **systemInstructionのrole**: `role: 'user'`になっているため、システム指示としての強制力が弱い

**Actionable Insights:**

1. **`buildSystemPrompt` 関数から "Always confirm..." を削除し、"Do not describe the action in text. Directly call the function to execute the action." を追加** – **gemini.ts** – **ユーザーが「クリックして」と言った際、"I will click..." というテキストレスポンスなしで、即座にツールが実行される**

2. **`systemInstruction` の `role` を `'user'` から `'system'` に変更** – **gemini.ts** – **モデルがSystem Promptの指示をより厳密に遵守するようになる**

3. **`getGenerativeModel` 呼び出し時に、`toolConfig: { functionCallingConfig: { mode: 'AUTO' } }` を追加** – **gemini.ts** – **曖昧なケースでもモデルがツール使用を優先し、Function Callingのトリガー率が向上する**

---

## PHASE 2: FINAL SYNTHESIS & UNIFIED ACTION PLAN

**Synthesis Engine**: CASPER-03 (Gemini) | **Integration Status**: ✓ COMPLETE

### Unified Action Plan

#### Step 1: Remove "Always Confirm" Constraint from System Prompt
**Owner**: Developer
**ETA**: 10分
**Deliverable**: 更新されたgemini.ts（`buildSystemPrompt`関数）
**Verification method**: ユーザーが「Click the signup button」とクエリした際、`click_element` function callが直接トリガーされ、「Should I click...?」というテキスト応答が発生しないこと

**実装内容:**
```typescript
// src/lib/gemini.ts の buildSystemPrompt 関数内
// 削除: "Always confirm what action you're about to take before executing it."
// 追加: "When a user request implies an action, call the appropriate tool immediately without asking for permission."
```

#### Step 2: Enforce Explicit Function Calling Configuration
**Owner**: Developer
**ETA**: 15分
**Deliverable**: gemini.tsに`toolConfig`設定を追加
**Verification method**: コードレビューで`toolConfig`が渡されていることを確認。機能テストでツールが引き続きアクセス可能であることを確認

**実装内容:**
```typescript
// src/lib/gemini.ts の sendMessageWithTools 関数内
const modelWithTools = this.genAI.getGenerativeModel({
  model: this._modelName,
  tools: [{ functionDeclarations: browserTools }],
  toolConfig: {
    functionCallingConfig: {
      mode: 'AUTO'  // 注: ANYではなくAUTOを使用（会話能力を維持）
    }
  },
})
```

**注記**: BALTHASAR-02は`ANY`を提案したが、MELCHIOR-01の指摘通り、`ANY`は非アクションクエリ（「Hello」等）でも強制的にツールを呼ぼうとして破綻する。`AUTO`に攻撃的なプロンプト（Step 1）を組み合わせることで、`ANY`の応答性を得つつユーザビリティを維持する。

#### Step 3: Strengthen Tool Definitions (Prompt Engineering)
**Owner**: Developer
**ETA**: 10分
**Deliverable**: 更新された`browserTools`定義
**Verification method**: 曖昧なクエリ（例: "Go to the next page"）が「Next」ボタンで`click_element`をより確実にトリガーすること

**実装内容:**
```typescript
// src/lib/gemini.ts の browserTools 定義
const browserTools: FunctionDeclaration[] = [
  {
    name: 'click_element',
    description: 'IMPORTANT: Use this function to click an element on the page using a CSS selector. Use this to interact with buttons, links, or other clickable elements.',
    // ... parameters ...
  },
  {
    name: 'fill_element',
    description: 'IMPORTANT: Use this function to fill an input or textarea element with text using a CSS selector. Use this to enter text into form fields.',
    // ... parameters ...
  },
  {
    name: 'get_html',
    description: 'IMPORTANT: Use this function to get the HTML content of an element or the entire page. Use this to inspect page structure or get specific element content.',
    // ... parameters ...
  },
]
```

### Consensus Highlights

1. **設定の明示化が重要**: すべての分析が、現在の実装がデフォルト動作に依存しすぎていることに合意。`toolConfig`の明示的な設定が信頼性向上に不可欠
2. **System Promptの矛盾**: System Promptの"Always confirm"指示が、自律的なツール実行を妨げる主要なブロッカーであることに3ペルソナが合意

### Conflicts / Trade-offs

**対立点**: **`ANY`（強制）vs `AUTO`（動的）**
- BALTHASAR-02: `ANY`を強制してツール使用を保証すべき
- MELCHIOR-01: `ANY`は会話能力を破壊する（「What is this page?」等の非アクションクエリに対応できない）

**解決策**: **`AUTO`に攻撃的なプロンプトを組み合わせる**
- Step 1 & 3で"confirmation"制約を削除し、ツール定義を強化することで、`ANY`の応答性を`AUTO`で実現
- ユーザビリティのダウンサイドを回避
- 将来的に`AUTO`が不安定な場合は、動的に`ANY`へ切り替えるオプションを留保

### Risk

**トリガー**: モデルが「強制されている」と感じ、存在しないセレクタを発明する等、ツール呼び出しや引数をハルシネートする可能性

**Mitigation**:
- `FunctionCallResult`ハンドラ（`src/lib/gemini.ts`または`background/index.ts`）で失敗を堅牢に処理
- 「Element not found」等のエラーをモデルにフィードバックし、再試行または明確化を求めさせる
- サイレントな失敗を防ぐ

### Follow-up Question

**Should we implement a "retry loop"?**
ツール呼び出しが失敗した場合（例: 無効なセレクタ）、システムが自動的にエラーをGeminiにフィードバックし、別のセレクタで再試行させるべきか？それとも即座にユーザーに失敗を報告すべきか？

---

## MAGI SYSTEM STATUS: DELIBERATION COMPLETE

**実行時間**: 約15分
**使用モデル**:
- MELCHIOR-01: Claude Sonnet 4.5
- BALTHASAR-02: Codex/GPT-5 (codex-cli 0.89.0)
- CASPER-03: Gemini 2.0 Flash (gemini-cli 0.23.0)

**次のアクション**:
1. gemini.tsの3つの変更を実装（合計ETA: 35分）
2. Playwrightテストを再実行（13 passedを確認）
3. 実際のGemini Side Panelで「ボタンをクリックして」をテストし、Function Call発火を確認
