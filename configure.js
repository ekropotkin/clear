'use strict'
const fs = require('fs')
const AWS = require('aws-sdk')

const stage = process.argv[2]

const STACKS = [
    {
        "StackName": "MyService-Stack-" + stage,
        "ConfigName": "MY_SERVICE",
        "Vars": [ "ApiUrl", "CognitoUserPoolId", "CognitoUserPoolClientId" ]
    }
]

const cf = new AWS.CloudFormation()
let configData = {}

for (let s = 0; s < STACKS.length; s++) {
    let config = STACKS[s]
    if (!configData[config.ConfigName]) {
        configData[config.ConfigName] = {}
    }
    console.log("describe stack")
    let isLast = false
    if (s == STACKS.length - 1) {
        isLast = true
    }
    cf.describeStacks({StackName: config.StackName}, function (err, data) {
        if (err) {
            console.log(`could not describe stack ${config.StackName}`)
            stop(1)
        }
        if (data.Stacks.length == 0) {
            console.log(`No stack ${config.StackName} found`)
            stop(1)
        }

        console.log("Looping over outputs")
        console.log(JSON.stringify(data.Stacks))
        let stackDetails = data.Stacks[0]
        for (let o = 0; o < stackDetails.Outputs.length; o++) {
            let curOutput = stackDetails.Outputs[o]
            console.log(`looking at var ${curOutput.OutputKey}`)
            for (let v = 0; v < config.Vars.length; v++) {
                if (curOutput.OutputKey == config.Vars[v]) {
                    configData[config.ConfigName][curOutput.OutputKey] = curOutput.OutputValue
                }
            }
        }

        if (isLast) {
            console.log("Writing data")
            let configFilePath = __dirname + "/src/config.json"
            fs.writeFileSync(configFilePath, JSON.stringify(configData))
        }
    })
}


function stop(code) {
    process.exit(code)
}
