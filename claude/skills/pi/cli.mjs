#!/usr/bin/env node
/**
 * agent-os-pi CLI — global command wrapper
 * Usage: agent-os-pi [workspace-dir] [--message "prompt"] [--help]
 */
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Re-export main script
await import(join(__dirname, 'agent-os-pi.mjs'));
