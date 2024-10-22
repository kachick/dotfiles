import { info } from "npm:@actions/core@^1.11.1";
import { context } from "npm:@actions/github@^6.0.0";

import { parseArgs } from "jsr:@std/cli/parse-args";

const flags = parseArgs(Deno.args, {
  string: ["paths"],
});

const { paths: pathLines } = flags;

const paths = pathLines ? pathLines.split(/\r?\n/) : [];

const higherMacOSPossibility = paths.some((path) => path.includes("darwin") || path === "home-manager/packages.nix");

const fastRunners = ["ubuntu-24.04", "macos-15"] as const;

const runners = (higherMacOSPossibility || context.eventName !== "pull_request")
  ? [...fastRunners, "macos-13"]
  : fastRunners;

// info(context.eventName) // Debug logger
info(JSON.stringify(runners));
