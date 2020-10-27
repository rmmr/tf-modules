const path = require("path")
const { Builder } = require("@sls-next/lambda-at-edge")

const rootDir = process.cwd()

const minifyHandlers = process.env.MINIFY_HANDLERS === '1' ? true : false
const useServerlessTraceTarget = process.env.USE_SERVERLESS_TRACE_TARGETS === '1' ? true : false

console.log('building')
console.log(minifyHandlers)
console.log(useServerlessTraceTarget)

const builder = new Builder(
  rootDir,
  path.join(rootDir, ".serverless_next"),
  {
    cmd: './node_modules/.bin/next',
    cwd: rootDir,
    env: {},
    args: ['build'],
    minifyHandlers,
    useServerlessTraceTarget,
  }
);

async function main() {
  await builder.build()
}

main()