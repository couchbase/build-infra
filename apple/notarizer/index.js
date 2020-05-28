#!/usr/bin/env node

const formidable = require('express-formidable')
const exec = require('child_process').exec
const istextorbinary = require('istextorbinary')
const logger = require('./logger.js')
const express = require("express")
const mkdirp = require('mkdirp')
const path = require("path")
const glob = require('glob')
const fs = require('fs')

const workdir = "workdir"
const port = process.env.PORT || "7000"
const codesignArgs = "--force --timestamp --options=runtime --verbose --entitlements couchbase.entitlement --preserve-metadata=identifier,requirements"
const maxLogAge = 1000 * 60 * 60 * 24       // retain 24 hours of logs
const logPurgeInterval = 1000 * 60 * 60     // hourly garbage collection
const notarizerPollInterval = 1000 * 60     // query notarizer service for status every minute
const notarizerTimeout = 1000 * 60 * 60 * 6 // give up waiting for notarization after 6 hours

const authToken = process.env.AUTH_TOKEN
const certName = process.env.DEVELOPER_ID
const appStoreUser = process.env.APP_STORE_USER
const appStorePass = process.env.APP_STORE_PASS

var app = express()
app.timeout = 1000 * 60 * 60 * 30 // 30 minutes
app.use(formidable())

// We use a global array of objects for holding logs in the following format
// {
//     date,
//     bundle,
//     severity,
//     string
// }
// This is to provide a mechanism by which logs can be retrieved by the requester i.e:
//   POST to /zip/foo (bundle=`bar`)
//   GET from /log/`bar`
let logs = []


// Add a message to the logs
function log(severity, message, bundle = '') {
    logger.log(severity, (bundle ? `(${bundle}) ` : '') + `${sanitize(message)}`)
    logs = logs.concat({
        bundle, severity, message: sanitize(message), date: new Date()
    })
}


// Strip known secrets from a string
function sanitize(input) {
    if (typeof input === 'string' || input instanceof String)
        return input.replace(appStoreUser, '******')
            .replace(appStorePass, '******')
            .replace(authToken, '******')
            .replace(certName, '******')
}


// Expire log messages older than maxLogAge
function purgeOldLogs() {
    logs = logs.filter(log => log.date > new Date(Date.now() - maxLogAge))
}


// Format date stamp for inclusion in logs
function formatDateStamp(date) {
    return `${date.toISOString().split('T')[0]} ${date.toISOString().split('T')[1].split('.')[0]}`
}


// Send log output when a GET request is received on /log/[bundle]
function sendLogs(res, bundle) {
    res.send(logs.filter(x => x.bundle === bundle).map(log => `${formatDateStamp(log.date)} [${log.severity}] ${log.message}`).join('\n') + '\n')
}


// Make a copy of `source` file as `dest` in bundle workdir
function copy(source, dest, bundle) {
    return new Promise((resolve, reject) =>
        fs.createReadStream(source).pipe(fs.createWriteStream(`${workdir}/${bundle}/${dest}`))
            .on('finish', data => {
                log('info', `Saved: ${dest}`, bundle)
                resolve(dest)
            })
            .on('error', err => {
                reject(`Couldn't save ${dest}: ${err}`)
            }))
}


// Use unzip to extract `zipfile` contents to bundle workdir
function extract(zipfile, bundle) {
    return new Promise((resolve, reject) =>
        exec(`unzip -o ${workdir}/${bundle}/${zipfile} -d ${workdir}/${bundle}`, (error, stdout, stderr) => {
            if (!error) {
                log('info', `Extracted: ${zipfile}`, bundle)
                resolve(stdout)
            }
            else {
                reject(`Couldn't extract ${zipfile}: ${error}`)
            }
        }))
}


// Use zip to freshen `zipfile` in bundle workdir with updated files
function freshen(zipfile, bundle) {
    return new Promise((resolve, reject) =>
        exec(`cd ${workdir}/${bundle} && zip -f ${zipfile}`)
            .on('close', () => {
                log('info', `Freshened ${zipfile}`, bundle)
                resolve(path.resolve(zipfile))
            })
            .on('error', err => {
                reject(`Couldn't freshen ${zipfile}: ${err}`)
            }))
}

// Get a list of binaries in [bundle workdir]/`basedir`/`folder`
// todo: need to handle single binaries being provided? currently only works with folders
function binaryList(basedir, folder, bundle) {
    return glob.sync(`${workdir}/${bundle}/${basedir}/${folder}/**/*`).filter(
        file => istextorbinary.isBinary(file, file ? fs.readFileSync(file) : null)
    )
}


// Use codesign to sign `file`
function sign(file, bundle) {
    return new Promise((resolve, reject) =>
        exec(
            `codesign ${codesignArgs} --sign \"${certName}\" \"${file}\"`, (error, stdout, stderr) => {
                if (error) {
                    reject(`Failed to sign: ${file} (${sanitize(error)}, ${sanitize(stderr)})`)
                }
                else log('info', `Signed: ${file}`, bundle)
            })
            .on('close', () => resolve())
            .on('error', err => reject(`Failed to sign ${file}: ${sanitize(err)}`)))
}


// Loop through `basedir`/`locations` passing every found file to sign()
//
// `locations` is an array of strings representing paths in which to target binaries
function signBinaries(basedir, locations, bundle) {
    return new Promise((resolve, reject) => {
        // get a list of relative paths to all the binaries we intend to process up front
        binaries = locations.map(loc => binaryList(basedir, loc, bundle)).flat()
        binaries.map(x => log('info', `Added to sign queue: ${x}`, bundle))

        // sign the files
        return Promise.all(binaries.map(binary => sign(binary, bundle)))
            .then(() => {
                resolve()
            }).catch(err => {
                reject(err)
            })
    })
}


// Use xcrun altool to notarize `file` in bundle workdir using `bundleId` as the primary bundle id
function notarize(file, bundle) {
    return new Promise((resolve, reject) => {
        log('info', `Notarizing ${file}`, bundle)
        const child = exec(`xcrun altool --notarize-app -t osx -f ${workdir}/${bundle}/${file} --primary-bundle-id ${bundle} -u ${appStoreUser} -p ${appStorePass}`, (error, stdout, stderr) => {
            if (error) {
                reject(`Failed to sign: ${file} (${sanitize(error)}, ${sanitize(stderr)})`)
            }
            else {
                const requestUUID = stdout.match(new RegExp(/RequestUUID = ([^\s$]*)/))[1].trim()
                log('info', `RequestUUID: ${requestUUID}`, bundle)
                resolve(requestUUID)
            }
        })
        child.on('error', err => {
            reject(`Failed to sign ${file}: ${sanitize(err)}`)
        })
    })
}


// Use xcrun altool to check status of existing notarization request by `uuid`
function notarizationStatus(uuid, bundle) {
    return new Promise((resolve, reject) =>
        exec(`xcrun altool --notarization-info ${uuid} -u ${appStoreUser} -p ${appStorePass}`, (error, stdout, stderr) => {
            if (error) {
                // note: the request seems to propogate to backend servers in a delayed manner.
                // It's not unusual to see ping-ponging between failures and successes here
                reject(`Failed to check status of ${uuid} (possibly a delay in replication): ${sanitize(stderr)}`)
            }
            else {
                resolve(stdout.match(new RegExp(/Status: (.*)/))[1].trim())
            }
        })
            .on('error', err => {
                reject(`Failed to sign ${file}: ${sanitize(err)}`)
            }))
}

// Wait for notarization `uuid` to complete successfully
function waitForNotarization(uuid, bundle) {
    return new Promise((resolve, reject) => {
        let timer = setInterval(() => {
            notarizationStatus(uuid).then((status) => {
                switch (status) {
                    case "success":
                        clearInterval(timer)
                        log('info', `Notarization successful: ${uuid}`, bundle)
                        resolve(status)
                        break
                    case "invalid":
                        clearInterval(timer)
                        reject(status)
                        break
                    case "failed": // todo: look statuses up, this is a guess
                        clearInterval(timer)
                        reject(status)
                        break
                    case "in progress":
                        break
                    default:
                        log('info', `Unhandled status, please check: ${status}`, bundle)
                        break
                }
            }).catch(e => console.log(e))
        }, notarizerPollInterval)
        setTimeout(() => { if (timer) clearInterval(timer) }, notarizerTimeout)
    })
}

// Purge files left behind by a previous run
function deleteBundleData(bundle) {
    return new Promise((resolve, reject) => {
        if (fs.existsSync(`${workdir}/${bundle}`)) {
            fs.rmdir(`${workdir}/${bundle}`, { recursive: true }, err => {
                if (!err) {
                    log('info', `Deleted bundle data`, bundle)
                    resolve()
                } else {
                    reject(`Couldn't delete bundle data: ${err}`)
                }
            })
        } else {
            resolve()
        }
    })
}


// The zip we extract has a build number in the filename, whereas the extracted content top level dir does not
// we need to figure out what the directory we just extracted is called so we can target the binaries for
// signing
function getExtractedDirName(archive, bundle) {
    return new Promise((resolve, reject) => {
        fs.readdir(`${workdir}/${bundle}`, function (err, items) {
            log('info', `Found extracted dir - ${items.filter(item => item != archive)[0]}`, bundle)
            if (err) reject(err)
            else resolve(items.filter(item => item != archive)[0])
        });
    })
}


if (!authToken || !certName || !appStoreUser || !appStorePass) {
    log('error', 'AUTH_TOKEN, DEVELOPER_ID, APP_STORE_USER and APP_STORE_PASS must be set')
    process.exit(1)
}

setInterval(() => purgeOldLogs(), logPurgeInterval)

//----------------//
// logs endpoint  //
//----------------//
// client can connect specifying a bundle name as a URL parameter to retrieve logs for that bundle
// it feels clunky allowing the client to specify the bundle name, but as we can't pass a generated
// bundle id back along with the zipfile, and presumably don't want consecutive jobs to dirty up or
// overwrite the previous bundle's logs, this seemed like the cleanest way of doing it
//
// bundle logs are retrieve-once
app.get('/log/*', (req, res) => {
    bundle = req.params[0]
    sendLogs(res, bundle)
    logs = logs.filter(x => x.bundle !== bundle)
})


//-------------------------------//
// signing+notarisation endpoint //
//-------------------------------//
// We use a wildcard here to allow the target filename to be used when downloading the result e.g:
//    $ curl -LOfsX POST \
//           --connect-timeout 21600 \
//           -F "notarize=true" \
//           -F "binary_locations=bin" \
//           -F "bundle=com.couchbase.autonomous-operator-kubernetes" \
//           -F "content=@couchbase-operator-UNSIGNED.zip" \
//           -F "token=ABC123" \
//           http://notarization-service:7000/zip/couchbase-operator-NOTARIZED.zip
app.post('/zip/*', (req, res) => {
    const archive = req.files.content.name
    const notarizing = req.fields.notarize
    const bundle = req.fields.bundle
    const token = req.fields.token
    const tmpfile = req.files.content.path
    const binaryPaths = req.fields.binary_locations.split('|')
    if (token != authToken) {
        log('error', "No auth token provided", bundle)
        res.status(500).send("No authtoken provided");
        return
    }
    sessionDir = `${workdir}/${bundle}`
    log('info', `working in ${sessionDir}`)
    const serveFile = (file, bundle) => {
        res.sendFile(file);
        log('info', `Served: ${file}`, bundle)
    }

    deleteBundleData(bundle)
        .then(() => mkdirp(sessionDir))
        .then(() => copy(tmpfile, archive, bundle)) // copy tmp file to workdir
        .then(() => { // ...SIGNING...
            return extract(archive, bundle)                                            // extract archive
                .then(() => getExtractedDirName(archive, bundle))                      // discover extracted dir name
                .then(extractedDir => signBinaries(extractedDir, binaryPaths, bundle)) // sign binaries
                .then(() => freshen(archive, bundle))                                  // freshen archive
                .then(() => sign(`${workdir}/${bundle}/${archive}`, bundle))           // sign archive
        })
        .then(() => { // ...NOTARIZE...
            if (notarizing.toLowerCase() == 'true') {
                return notarize(archive, bundle)                     // send notarization request
                    .then(uuid => waitForNotarization(uuid, bundle)) // wait for notarization success
            }
        })
        // return signed+notarized archive to uploader
        .then(() => serveFile(path.resolve(`${workdir}/${bundle}/${archive}`), bundle))
        .catch(err => {
            log('error', `${err}`, bundle)
            res.status(500).send(err)
        })

})

app.listen(port, () => {
    log('info', `Listening on port ${port}`);
});
