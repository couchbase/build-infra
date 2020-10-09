#!/usr/bin/env -S deno run --allow-read --allow-run

// This script reads /patterns.json, and loops through running ag in the current
// work directory against each.
//
// If any patterns are detected we provide a remediation recommendation and exit
// with return code 1, otherwise we exit 0

let exitCode = 0

// If we've been passed an argument, treat it as the directory we intend to scan
if (Deno?.args?.[0]) Deno.chdir(Deno.args[0])

async function getJson(filename) {
    return JSON.parse(await Deno.readTextFile(filename))
}

const patterns = await getJson('/patterns.json')

// Walk through list of patterns running ag against them and treating successes
// (no matches) and failures (matches) accordingly
for (let i = 0; i < patterns?.length; i++) {
    const outstr = `Checking pattern: ${patterns[i].name}`
    console.log(`${outstr}\n${'-'.repeat(outstr.length)}`)
    const p = Deno.run({
        cmd: ['ag', patterns[i].pattern]
    })
    const { code } = await p.status()
    p.close()

    if (code === 0) {
        // match
        console.log("WARNING: matches found")
        console.log("Remediation:", patterns[i].remediation)
        console.log()
        exitCode = 1
    } else {
        // no match
        console.log("No matches")
        console.log()
    }
}

Deno.exit(exitCode)
