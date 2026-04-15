#!/usr/bin/env npx ts-node
/**
 * TypeScript Coupling Analyzer
 * Based on Vlad Khononov's Balanced Coupling Framework
 *
 * Usage: npx ts-node coupling-analyzer.ts [rootDir]
 *
 * Outputs: coupling-analysis.html
 */

import * as fs from "fs";
import * as path from "path";
import { execSync } from "child_process";

// ============================================================================
// Types
// ============================================================================

interface Coupling {
  source: string;
  target: string;
  strength: number;
  strengthType: "Intrusive" | "Functional" | "Model" | "Contract";
  distance: number;
  distanceType: "Same Module" | "Sibling Module" | "Distant Module" | "External";
  volatility: number;
  volatilityLevel: "Low" | "Medium" | "High" | "Unknown";
  balanceScore: number;
}

interface FileInfo {
  path: string;
  changes: number;
  volatility: number;
  volatilityLevel: "Low" | "Medium" | "High";
}

interface AnalysisResult {
  files: FileInfo[];
  couplings: Coupling[];
  summary: {
    totalFiles: number;
    totalCouplings: number;
    avgStrength: number;
    avgDistance: number;
    avgVolatility: number;
    balanceScore: number;
  };
}

// ============================================================================
// Constants
// ============================================================================

const STRENGTH_SCORES = {
  Intrusive: 1.0,
  Functional: 0.75,
  Model: 0.5,
  Contract: 0.25,
};

const DISTANCE_SCORES = {
  "Same Module": 0.25,
  "Sibling Module": 0.5,
  "Distant Module": 0.75,
  External: 1.0,
};

// ============================================================================
// File Discovery
// ============================================================================

function findTypeScriptFiles(dir: string): string[] {
  const files: string[] = [];
  const excludeDirs = ["node_modules", ".git", "dist", "build", ".next", ".expo"];
  const excludePatterns = [".d.ts", ".stories.", ".test.", ".spec."];

  function walk(currentDir: string) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);

      if (entry.isDirectory()) {
        if (!excludeDirs.includes(entry.name)) {
          walk(fullPath);
        }
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name);
        if ([".ts", ".tsx", ".js", ".jsx"].includes(ext)) {
          if (!excludePatterns.some((p) => entry.name.includes(p))) {
            files.push(fullPath);
          }
        }
      }
    }
  }

  walk(dir);
  return files;
}

// ============================================================================
// Git Volatility
// ============================================================================

function getGitVolatility(rootDir: string): Map<string, number> {
  const volatilityMap = new Map<string, number>();

  try {
    const output = execSync(
      'git log --since="6 months ago" --name-only --pretty=format: -- "*.ts" "*.tsx" "*.js" "*.jsx"',
      { cwd: rootDir, encoding: "utf-8", maxBuffer: 50 * 1024 * 1024 }
    );

    const lines = output.split("\n").filter((l) => l.trim());
    for (const line of lines) {
      const count = volatilityMap.get(line) || 0;
      volatilityMap.set(line, count + 1);
    }
  } catch {
    console.warn("Git history not available");
  }

  return volatilityMap;
}

function getVolatilityLevel(changes: number): "Low" | "Medium" | "High" {
  if (changes <= 2) return "Low";
  if (changes <= 10) return "Medium";
  return "High";
}

function getVolatilityScore(level: "Low" | "Medium" | "High" | "Unknown"): number {
  switch (level) {
    case "Low":
      return 0;
    case "Medium":
      return 0.5;
    case "High":
      return 1.0;
    default:
      return 0.25;
  }
}

// ============================================================================
// Import Extraction
// ============================================================================

function extractImports(filePath: string): Array<{ source: string; type: string }> {
  const content = fs.readFileSync(filePath, "utf-8");
  const imports: Array<{ source: string; type: string }> = [];

  // Standard imports: import X from 'Y'
  const importRegex = /import\s+(?:(?:\{[^}]+\}|\*\s+as\s+\w+|\w+)\s+from\s+)?['"]([^'"]+)['"]/g;
  let match;

  while ((match = importRegex.exec(content)) !== null) {
    const source = match[1];
    if (!source.startsWith(".") && !source.startsWith("@/") && !source.startsWith("~/")) {
      continue; // Skip external packages for detailed analysis
    }

    // Determine import type from the import statement
    const fullMatch = match[0];
    let type: string;

    if (fullMatch.includes("type ") || fullMatch.match(/import\s+\{[^}]*\btype\b/)) {
      type = "Contract";
    } else if (fullMatch.includes("* as")) {
      type = "Intrusive";
    } else {
      type = "Functional";
    }

    imports.push({ source, type });
  }

  return imports;
}

// ============================================================================
// Path Resolution
// ============================================================================

function resolveImportPath(fromPath: string, importSource: string, rootDir: string): string {
  const fromDir = path.dirname(fromPath);
  let basePath: string;

  if (importSource.startsWith("@/") || importSource.startsWith("~/")) {
    basePath = path.join(rootDir, importSource.slice(2));
  } else {
    basePath = path.resolve(fromDir, importSource);
  }

  const extensions = [".ts", ".tsx", ".js", ".jsx"];
  const candidates = [
    basePath,
    ...extensions.map((ext) => basePath + ext),
    ...extensions.map((ext) => path.join(basePath, "index" + ext)),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  return basePath;
}

// ============================================================================
// Distance Calculation
// ============================================================================

function calculateDistance(
  sourcePath: string,
  targetPath: string,
  rootDir: string
): { score: number; type: "Same Module" | "Sibling Module" | "Distant Module" | "External" } {
  const sourceRel = path.relative(rootDir, sourcePath);
  const targetRel = path.relative(rootDir, targetPath);

  const sourceDir = path.dirname(sourceRel);
  const targetDir = path.dirname(targetRel);

  if (sourceDir === targetDir) {
    return { score: DISTANCE_SCORES["Same Module"], type: "Same Module" };
  }

  const sourceParts = sourceDir.split(path.sep);
  const targetParts = targetDir.split(path.sep);

  if (sourceParts[0] === targetParts[0]) {
    return { score: DISTANCE_SCORES["Sibling Module"], type: "Sibling Module" };
  }

  return { score: DISTANCE_SCORES["Distant Module"], type: "Distant Module" };
}

// ============================================================================
// Balance Score
// ============================================================================

function calculateBalanceScore(strength: number, distance: number, volatility: number): number {
  const volatilityRisk = strength * volatility * 0.6;
  const distanceMismatch = Math.abs(strength - (1 - distance)) * 0.4;
  return Math.min(1, volatilityRisk + distanceMismatch);
}

// ============================================================================
// Main Analysis
// ============================================================================

function analyze(rootDir: string): AnalysisResult {
  const files = findTypeScriptFiles(rootDir);
  const volatilityMap = getGitVolatility(rootDir);

  const fileInfos: FileInfo[] = files.map((f) => {
    const relPath = path.relative(rootDir, f);
    const changes = volatilityMap.get(relPath) || 0;
    const volatilityLevel = getVolatilityLevel(changes);
    return {
      path: relPath,
      changes,
      volatility: getVolatilityScore(volatilityLevel),
      volatilityLevel,
    };
  });

  const couplings: Coupling[] = [];

  for (const file of files) {
    const imports = extractImports(file);

    for (const imp of imports) {
      const targetPath = resolveImportPath(file, imp.source, rootDir);
      const targetRel = path.relative(rootDir, targetPath);
      const targetChanges = volatilityMap.get(targetRel) || 0;
      const targetVolatilityLevel = targetChanges > 0 ? getVolatilityLevel(targetChanges) : "Unknown";

      const strength = STRENGTH_SCORES[imp.type as keyof typeof STRENGTH_SCORES] || 0.75;
      const distance = calculateDistance(file, targetPath, rootDir);
      const volatility = getVolatilityScore(targetVolatilityLevel);
      const balanceScore = calculateBalanceScore(strength, distance.score, volatility);

      couplings.push({
        source: path.relative(rootDir, file),
        target: imp.source,
        strength,
        strengthType: imp.type as Coupling["strengthType"],
        distance: distance.score,
        distanceType: distance.type,
        volatility,
        volatilityLevel: targetVolatilityLevel,
        balanceScore,
      });
    }
  }

  const avgStrength = couplings.length > 0 ? couplings.reduce((sum, c) => sum + c.strength, 0) / couplings.length : 0;
  const avgDistance = couplings.length > 0 ? couplings.reduce((sum, c) => sum + c.distance, 0) / couplings.length : 0;
  const avgVolatility =
    couplings.length > 0 ? couplings.reduce((sum, c) => sum + c.volatility, 0) / couplings.length : 0;
  const balanceScore =
    couplings.length > 0 ? couplings.reduce((sum, c) => sum + c.balanceScore, 0) / couplings.length : 0;

  return {
    files: fileInfos,
    couplings,
    summary: {
      totalFiles: files.length,
      totalCouplings: couplings.length,
      avgStrength,
      avgDistance,
      avgVolatility,
      balanceScore,
    },
  };
}

// ============================================================================
// HTML Report Generation
// ============================================================================

function generateHtmlReport(result: AnalysisResult, outputPath: string): void {
  const { summary, files, couplings } = result;

  const topChangedFiles = [...files].sort((a, b) => b.changes - a.changes).slice(0, 10);
  const riskyCouplings = couplings.filter((c) => c.balanceScore >= 0.4).sort((a, b) => b.balanceScore - a.balanceScore);
  const goodCouplings = couplings.filter((c) => c.balanceScore < 0.2).slice(0, 5);

  const html = `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Coupling Analysis Report</title>
  <script src="https://d3js.org/d3.v7.min.js"></script>
  <style>
    :root {
      --bg: #0d1117;
      --card: #161b22;
      --border: #30363d;
      --text: #c9d1d9;
      --text-muted: #8b949e;
      --accent: #58a6ff;
      --success: #3fb950;
      --warning: #d29922;
      --danger: #f85149;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
      padding: 2rem;
    }
    .container { max-width: 1400px; margin: 0 auto; }
    h1 { font-size: 2rem; margin-bottom: 0.5rem; color: #fff; }
    .subtitle { color: var(--text-muted); margin-bottom: 2rem; }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1.5rem;
      margin-bottom: 1.5rem;
    }
    .card-title {
      font-size: 1.1rem;
      margin-bottom: 1rem;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
    }
    .stat {
      background: var(--bg);
      border-radius: 6px;
      padding: 1rem;
      text-align: center;
    }
    .stat-value { font-size: 2rem; font-weight: bold; color: var(--accent); }
    .stat-label { font-size: 0.85rem; color: var(--text-muted); }
    .stat-meaning { font-size: 0.75rem; color: var(--text-muted); margin-top: 0.5rem; }
    .two-col {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1.5rem;
    }
    @media (max-width: 900px) { .two-col { grid-template-columns: 1fr; } }
    .badge {
      display: inline-block;
      padding: 0.2rem 0.6rem;
      border-radius: 12px;
      font-size: 0.75rem;
      font-weight: 500;
    }
    .badge-high { background: rgba(248, 81, 73, 0.2); color: var(--danger); }
    .badge-medium { background: rgba(210, 153, 34, 0.2); color: var(--warning); }
    .badge-low { background: rgba(63, 185, 80, 0.2); color: var(--success); }
    .file-item {
      display: grid;
      grid-template-columns: 60px 80px 1fr;
      gap: 1rem;
      padding: 0.75rem;
      border-bottom: 1px solid var(--border);
      align-items: center;
    }
    .coupling-item { padding: 1rem; border-bottom: 1px solid var(--border); }
    .coupling-path { font-family: monospace; font-size: 0.9rem; color: var(--text-muted); }
    .coupling-path .arrow { color: var(--accent); margin: 0 0.5rem; }
    .coupling-score {
      font-family: monospace;
      font-weight: bold;
      padding: 0.25rem 0.5rem;
      border-radius: 4px;
    }
    .score-risky { background: rgba(248, 81, 73, 0.2); color: var(--danger); }
    .score-good { background: rgba(63, 185, 80, 0.2); color: var(--success); }
    .insight-box {
      background: rgba(88, 166, 255, 0.1);
      border-left: 3px solid var(--accent);
      padding: 0.75rem 1rem;
      margin-top: 1rem;
      font-size: 0.85rem;
    }
    .warning-box {
      background: rgba(248, 81, 73, 0.1);
      border-left: 3px solid var(--danger);
      padding: 0.75rem 1rem;
      margin-top: 1rem;
      font-size: 0.85rem;
    }
    #graph-container { width: 100%; height: 400px; background: var(--bg); border-radius: 8px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Coupling Analysis Report</h1>
    <p class="subtitle">Based on Vlad Khononov's Balanced Coupling Framework</p>

    <div class="card">
      <h2 class="card-title">Summary Statistics</h2>
      <div class="stats-grid">
        <div class="stat">
          <div class="stat-value">${summary.avgStrength.toFixed(2)}</div>
          <div class="stat-label">Average Strength</div>
          <div class="stat-meaning">${summary.avgStrength >= 0.75 ? "Functional level - component/hook usage is central" : summary.avgStrength >= 0.5 ? "Model level - data type imports dominate" : "Contract level - loose interface coupling"}</div>
        </div>
        <div class="stat">
          <div class="stat-value">${summary.avgDistance.toFixed(2)}</div>
          <div class="stat-label">Average Distance</div>
          <div class="stat-meaning">${summary.avgDistance >= 0.75 ? "Cross-module dependencies are common" : summary.avgDistance >= 0.5 ? "Mix of local and distant imports" : "Dependencies mostly within same area"}</div>
        </div>
        <div class="stat">
          <div class="stat-value">${summary.avgVolatility.toFixed(2)}</div>
          <div class="stat-label">Average Volatility</div>
          <div class="stat-meaning">${summary.avgVolatility >= 0.5 ? "High change rate - watch for ripple effects" : "Stable codebase - lower change risk"}</div>
        </div>
        <div class="stat">
          <div class="stat-value" style="color: ${summary.balanceScore < 0.2 ? "var(--success)" : summary.balanceScore < 0.4 ? "var(--text)" : summary.balanceScore < 0.6 ? "var(--warning)" : "var(--danger)"};">${summary.balanceScore.toFixed(2)}</div>
          <div class="stat-label">Balance Score</div>
          <div class="stat-meaning">${summary.balanceScore < 0.2 ? "Ideal range - well-architected" : summary.balanceScore < 0.4 ? "Acceptable - minor improvements possible" : summary.balanceScore < 0.6 ? "Needs attention - refactoring recommended" : "Risky - urgent refactoring needed"}</div>
        </div>
      </div>
    </div>

    <div class="card">
      <h2 class="card-title">Most Frequently Changed Files (6 months)</h2>
      <div class="file-list">
        ${topChangedFiles
          .map(
            (f) => `
        <div class="file-item">
          <span style="font-weight: bold; font-family: monospace;">${f.changes}</span>
          <span class="badge badge-${f.volatilityLevel.toLowerCase()}">${f.volatilityLevel}</span>
          <span>${f.path}</span>
        </div>`
          )
          .join("")}
      </div>
    </div>

    <div class="two-col">
      <div class="card">
        <h2 class="card-title">Risky Couplings</h2>
        ${riskyCouplings
          .slice(0, 5)
          .map(
            (c) => `
        <div class="coupling-item">
          <div style="display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.5rem;">
            <span class="coupling-score score-risky">${c.balanceScore.toFixed(2)}</span>
            <span class="badge badge-${c.volatilityLevel.toLowerCase()}">${c.volatilityLevel} Volatility</span>
            <span class="badge">${c.strengthType}</span>
          </div>
          <div class="coupling-path">${c.source} <span class="arrow">→</span> ${c.target}</div>
        </div>`
          )
          .join("")}
        ${riskyCouplings.length > 0 ? `<div class="warning-box">These couplings have high change risk. Consider introducing interfaces or splitting modules.</div>` : `<div class="insight-box">No risky couplings found. Great architecture!</div>`}
      </div>

      <div class="card">
        <h2 class="card-title">Well-Balanced Couplings</h2>
        ${goodCouplings
          .map(
            (c) => `
        <div class="coupling-item">
          <div style="display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.5rem;">
            <span class="coupling-score score-good">${c.balanceScore.toFixed(2)}</span>
            <span class="badge badge-low">Low Volatility</span>
            <span class="badge">${c.strengthType}</span>
          </div>
          <div class="coupling-path">${c.source} <span class="arrow">→</span> ${c.target}</div>
        </div>`
          )
          .join("")}
        <div class="insight-box">Same-directory dependencies with low volatility are ideal patterns.</div>
      </div>
    </div>

    <div class="card">
      <h2 class="card-title">Dependency Graph</h2>
      <div id="graph-container"></div>
    </div>
  </div>

  <script>
    const data = ${JSON.stringify({
      nodes: Array.from(new Set([...couplings.map((c) => c.source), ...couplings.map((c) => c.target)])).map((id) => ({
        id,
        volatility: files.find((f) => f.path === id)?.volatilityLevel || "Unknown",
      })),
      links: couplings.map((c) => ({ source: c.source, target: c.target, score: c.balanceScore })),
    })};

    const container = document.getElementById('graph-container');
    const width = container.clientWidth;
    const height = 400;

    const svg = d3.select('#graph-container')
      .append('svg')
      .attr('width', width)
      .attr('height', height);

    const color = d => {
      if (d.volatility === 'High') return '#f85149';
      if (d.volatility === 'Medium') return '#d29922';
      return '#3fb950';
    };

    const simulation = d3.forceSimulation(data.nodes)
      .force('link', d3.forceLink(data.links).id(d => d.id).distance(80))
      .force('charge', d3.forceManyBody().strength(-200))
      .force('center', d3.forceCenter(width / 2, height / 2));

    const link = svg.append('g')
      .selectAll('line')
      .data(data.links)
      .join('line')
      .attr('stroke', '#30363d')
      .attr('stroke-width', 1);

    const node = svg.append('g')
      .selectAll('circle')
      .data(data.nodes)
      .join('circle')
      .attr('r', 6)
      .attr('fill', color);

    node.append('title').text(d => d.id);

    simulation.on('tick', () => {
      link
        .attr('x1', d => d.source.x)
        .attr('y1', d => d.source.y)
        .attr('x2', d => d.target.x)
        .attr('y2', d => d.target.y);
      node
        .attr('cx', d => d.x)
        .attr('cy', d => d.y);
    });
  </script>
</body>
</html>`;

  fs.writeFileSync(outputPath, html);
  console.log(`Report generated: ${outputPath}`);
}

// ============================================================================
// Entry Point
// ============================================================================

const rootDir = process.argv[2] || process.cwd();
const outputPath = path.join(rootDir, "coupling-analysis.html");

console.log(`Analyzing: ${rootDir}`);
const result = analyze(rootDir);
generateHtmlReport(result, outputPath);

console.log(`\nSummary:`);
console.log(`  Files: ${result.summary.totalFiles}`);
console.log(`  Couplings: ${result.summary.totalCouplings}`);
console.log(`  Balance Score: ${result.summary.balanceScore.toFixed(2)}`);
