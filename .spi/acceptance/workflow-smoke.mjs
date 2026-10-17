import { mkdir, writeFile } from "node:fs/promises";
import { dirname } from "node:path";


function argumentsFrom(argv) {
  const values = new Map();
  for (let index = 0; index < argv.length; index += 2) {
    const name = argv[index];
    const value = argv[index + 1];
    if (!name?.startsWith("--") || value === undefined) {
      throw new Error(`Invalid argument at position ${index + 1}`);
    }
    values.set(name.slice(2), value);
  }

  for (const name of ["workflow-url", "partition", "token", "workflow-name", "report"]) {
    if (!values.has(name)) {
      throw new Error(`Missing required argument --${name}`);
    }
  }
  return Object.fromEntries(values);
}


function xml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}


async function writeReport(path, failure = null) {
  const failureNode = failure
    ? `<failure message="${xml(failure)}">${xml(failure)}</failure>`
    : "";
  const report = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<testsuite name="open-vds-prerequisite" tests="1" failures="${failure ? 1 : 0}">`,
    '<testcase classname="spi.openvds" name="conversion_workflow_is_registered">',
    failureNode,
    "</testcase>",
    "</testsuite>",
    "",
  ].join("\n");
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, report, "utf8");
}


async function main() {
  let options;
  try {
    options = argumentsFrom(process.argv.slice(2));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    return 2;
  }

  const endpoint = `${options["workflow-url"].replace(/\/$/, "")}/workflow/` +
    encodeURIComponent(options["workflow-name"]);
  try {
    const response = await fetch(endpoint, {
      headers: {
        Authorization: `Bearer ${options.token}`,
        "data-partition-id": options.partition,
      },
      signal: AbortSignal.timeout(30_000),
    });
    if (!response.ok) {
      throw new Error(`Workflow API returned HTTP ${response.status}`);
    }
    const body = await response.json();
    if (body === null || typeof body !== "object" || Array.isArray(body)) {
      throw new Error("Workflow API response must be a JSON object");
    }
  } catch (error) {
    const failure = `${error?.name ?? "Error"}: ${error?.message ?? String(error)}`;
    await writeReport(options.report, failure);
    console.error(failure);
    return 1;
  }

  await writeReport(options.report);
  console.log(`Workflow '${options["workflow-name"]}' is registered`);
  return 0;
}


process.exitCode = await main();
