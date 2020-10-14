const path = require("path")
const { Builder } = require("@sls-next/lambda-at-edge")

const rootDir = process.cwd()

const builder = new Builder(
  rootDir,
  path.join(rootDir, ".serverless_next"),
  {
    cmd: './node_modules/.bin/next',
    cwd: rootDir,
    env: {},
    args: ['build']
  }
);

async function main() {
  await builder.build()
}

main()