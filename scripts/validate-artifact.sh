#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${BUILD_ENV_READY:-}" != "1" ]]; then
  exec "${script_dir}/build-env.sh" -- "$0" "$@"
fi

worker="${BUILD_PROJECT_ROOT}/dist/server/index.js"
bindings="${BUILD_PROJECT_ROOT}/dist/.runtime/runtime-bindings.json"

[[ -f "${worker}" ]] || {
  echo "Missing worker entry: dist/server/index.js" >&2
  exit 66
}
[[ -f "${bindings}" ]] || {
  echo "Missing runtime binding config: dist/.runtime/runtime-bindings.json" >&2
  exit 66
}

node --input-type=module - "${worker}" "${bindings}" <<'NODE'
import { readFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";

const [workerPath, bindingsPath] = process.argv.slice(2);
JSON.parse(await readFile(bindingsPath, "utf8"));

const workerUrl = pathToFileURL(workerPath);
workerUrl.searchParams.set("validation", `${process.pid}-${Date.now()}`);
const worker = await import(workerUrl.href);
if (!worker.default || typeof worker.default.fetch !== "function") {
  throw new Error("dist/server/index.js must have an ESM default export with fetch(request, env, ctx)");
}
NODE

echo "Validated build: worker default.fetch and runtime binding config are present."
