#!/usr/bin/env -S deno run --allow-read --allow-run

// This script reads /patterns.json, and loops through running ag in the current
// work directory against each.
//
// If any patterns are detected we provide a remediation recommendation and exit
// with return code 1, otherwise we exit 0

let exitCode = 0

// If we've been passed an argument, treat it as the directory we intend to scan
if (Deno?.args?.[0]) Deno.chdir(Deno.args[0])

const getJson = async filename => JSON.parse(await Deno.readTextFile(filename))
const heading = text => console.log(`${text}\n${'-'.repeat(text.length)}`)

const patterns = await getJson('/patterns.json')

// Walk through list of patterns running ag against them and treating successes
// (no matches) and failures (matches) accordingly
for (let i = 0; i < patterns?.length; i++) {
    // patterns are enabled by default
    const enabled = !patterns[i].hasOwnProperty("enabled") || patterns[i].enabled
    // whole words are matched by default
    const wordMatch = !patterns[i].hasOwnProperty("word_match") || patterns[i].word_match;
    if (enabled) {
        heading(`Checking pattern: ${patterns[i].name}`)
        const exclude = patterns[i]?.exclusions ? `(?!${patterns[i].exclusions.join('|')})` : ''
        const pattern = patterns[i].pattern.replace("@EXCLUSIONS@", exclude)
        const args = ['ag', wordMatch ? '-w' : '', '-W200'].filter(arg => arg)
        for(const filePattern in patterns[i].whitelist) {
            args.push('--ignore')
            args.push(`${patterns[i].whitelist[filePattern]}`)
        }
        args.push(pattern)
        const p = Deno.run({
            cmd: args
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
    } else {
        console.log(`Skipped disabled pattern: ${patterns[i].name}`)
    }
}

Deno.exit(exitCode)
